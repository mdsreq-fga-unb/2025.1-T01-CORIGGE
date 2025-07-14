import pytest
import numpy as np
import cv2
from unittest.mock import patch, AsyncMock, MagicMock
from find_circles import find_circles_cv2, evaluate_circles_quality, find_circles_fallback, save_parameter_circle_counts
from utils import Utils
from websocket_types import BoxRectangleType
import json
import os

# Mock the Utils.log_info and Utils.log_error to prevent console output during tests
@pytest.fixture(autouse=True)
def mock_utils_logging():
    with patch.object(Utils, 'log_info', new=MagicMock()), \
         patch.object(Utils, 'log_error', new=MagicMock()):
        yield

# Mock the save_parameter_circle_counts to prevent file I/O during tests
@pytest.fixture(autouse=True)
def mock_save_parameter_circle_counts():
    with patch('find_circles.save_parameter_circle_counts', new=MagicMock()):
        yield

@pytest.mark.asyncio
async def test_find_circles_cv2_basic_detection():
    # Mock cv2 functions
    with patch('cv2.imread', return_value=np.full((1000, 1000, 3), 255, dtype=np.uint8)), \
         patch('cv2.resize', return_value=np.full((4000, 4000, 3), 255, dtype=np.uint8)), \
         patch('cv2.GaussianBlur', return_value=np.full((4000, 4000, 3), 255, dtype=np.uint8)), \
         patch('cv2.cvtColor', return_value=np.full((4000, 4000), 255, dtype=np.uint8)), \
         patch('cv2.HoughCircles', return_value=np.array([[[2000, 2000, 50]]], dtype=np.float32)):
        
        # Mock the internal iterative function to return a controlled result
        with patch('find_circles.find_circles_hough_iterative', new_callable=AsyncMock) as mock_iterative:
            mock_iterative.return_value = (
                np.array([[[2000, 2000, 50]]], dtype=np.float32), # circles
                {'dp': 1, 'param1': 0.4, 'param2': 30, 'threshold': 230, 'min_dist': 120}, # best_params
                0.9, # best_score
                {'parameter_combinations': {}, 'final_circle_count': 1, 'total_combinations_tested': 1} # param_stats
            )

            rectangle = {'x': 0.1, 'y': 0.1, 'width': 0.2, 'height': 0.2}
            result = await find_circles_cv2(
                "dummy_path.jpg", 
                rectangle, 
                BoxRectangleType.OUTRO, 
                param2=30, 
                dp=1, 
                on_progress=AsyncMock()
            )
            
            assert len(result) == 1
            assert result[0]['filled'] == False # Default darkness_threshold is 180/255, mock image is all white (255)
            assert 'center_x' in result[0]
            assert 'center_y' in result[0]
            assert 'radius' in result[0]

@pytest.mark.asyncio
async def test_find_circles_cv2_filled_circle_detection():
    # Mock cv2 functions and image content for a filled circle
    with patch('cv2.imread', return_value=np.zeros((1000, 1000, 3), dtype=np.uint8)), \
         patch('cv2.resize', return_value=np.zeros((4000, 4000, 3), dtype=np.uint8)), \
         patch('cv2.GaussianBlur', return_value=np.zeros((4000, 4000, 3), dtype=np.uint8)), \
         patch('cv2.cvtColor', return_value=np.zeros((4000, 4000), dtype=np.uint8)):
        
        # Mock the internal iterative function to return a controlled result
        with patch('find_circles.find_circles_hough_iterative', new_callable=AsyncMock) as mock_iterative:
            mock_iterative.return_value = (
                np.array([[[2000, 2000, 50]]], dtype=np.float32), # circles
                {'dp': 1, 'param1': 0.4, 'param2': 30, 'threshold': 230, 'min_dist': 120}, # best_params
                0.9, # best_score
                {'parameter_combinations': {}, 'final_circle_count': 1, 'total_combinations_tested': 1} # param_stats
            )

            # Create a mock crop_img that will result in a filled circle
            mock_crop_img = np.full((400, 400), 50, dtype=np.uint8) # Dark gray, below default darkness_threshold
            with patch('find_circles.cv2.cvtColor', return_value=mock_crop_img): # This mocks the gray image
                rectangle = {'x': 0.1, 'y': 0.1, 'width': 0.2, 'height': 0.2}
                result = await find_circles_cv2(
                    "dummy_path.jpg", 
                    rectangle, 
                    BoxRectangleType.OUTRO, 
                    param2=30, 
                    dp=1, 
                    darkness_threshold=100/255, # Set a threshold that makes the mock_crop_img "filled"
                    on_progress=AsyncMock()
                )
                
                assert len(result) == 1
                assert result[0]['filled'] == True

@pytest.mark.asyncio
async def test_find_circles_fallback_basic_detection():
    template_circles = [
        {"center_x": 0.5, "center_y": 0.5, "radius": 0.01}
    ]
    rectangle = {'x': 0, 'y': 0, 'width': 1, 'height': 1}
    
    # Create a mock image that is mostly white, but with a dark spot for the circle
    mock_img = np.full((1000, 1000, 3), 255, dtype=np.uint8)
    # Draw a dark circle in the center
    cv2.circle(mock_img, (500, 500), 10, (0, 0, 0), -1) # Filled black circle
    
    with patch('find_circles.cv2.imread', return_value=mock_img), \
         patch('find_circles.cv2.resize', return_value=mock_img): # Mock resize to return the same image
        
        result = await find_circles_fallback(
            "dummy_path.jpg", 
            rectangle, 
            BoxRectangleType.OUTRO, 
            template_circles, 
            darkness_threshold=100/255, # Set a threshold that makes the dark spot "filled"
            on_progress=AsyncMock(),
            img=mock_img # Pass the mock image directly
        )
        
        assert len(result) == 1
        assert result[0]['filled'] == True

def test_evaluate_circles_quality_perfect_match():
    # Test case for perfect match: 4 circles, no overlap, good radius consistency
    circles = np.array([
        [100, 100, 10],
        [100, 150, 10],
        [150, 100, 10],
        [150, 150, 10]
    ], dtype=np.float32)
    
    score = evaluate_circles_quality(
        (circles,), # Pass as tuple to match HoughCircles output
        expected_count=4, 
        min_radius=9, 
        max_radius=11, 
        img_shape=(200, 200, 3)
    )
    # Expect a high score for a perfect match (exact value might vary slightly due to weights)
    assert score > 0.8

def test_evaluate_circles_quality_overlap_penalty():
    # Test case for overlapping circles
    circles = np.array([
        [100, 100, 20],
        [105, 105, 20] # Heavily overlapping
    ], dtype=np.float32)
    
    score = evaluate_circles_quality((circles,))
    # Expect a low score due to overlap penalty
    assert score == pytest.approx(0.615, abs=0.001)

def test_evaluate_circles_quality_boundary_penalty():
    # Test case for circles outside boundaries
    circles = np.array([
        [10, 10, 20],
        [190, 190, 20]
    ], dtype=np.float32)
    
    score = evaluate_circles_quality((circles,), img_shape=(200, 200, 3))
    # Expect a lower score due to boundary penalty
    assert score < 0.8

# Test for save_parameter_circle_counts (mocking file operations)
def test_save_parameter_circle_counts_writes_file():
    mock_param_circle_counts = {
        "dp=1_p1=0.4_p2=2_th=220": 10,
        "dp=1_p1=0.4_p2=2_th=224": 12
    }
    rectangle_info = {
        "name": "test_rect",
        "index": 1,
        "total": 1,
        "page_info": ""
    }
    
    # Mock os.path.exists and json.dump/load
    with patch('os.path.exists', return_value=False), \
         patch('json.dump') as mock_json_dump, \
         patch('builtins.open', MagicMock()): # Mock open to prevent actual file access
        
        save_parameter_circle_counts(mock_param_circle_counts, BoxRectangleType.OUTRO, rectangle_info)
        
        mock_json_dump.assert_called_once()
        args, kwargs = mock_json_dump.call_args
        saved_data = args[0]
        
        assert "Outro" in saved_data
        assert len(saved_data["Outro"]) == 1
        assert saved_data["Outro"][0]["parameter_combinations"] == mock_param_circle_counts
        assert saved_data["Outro"][0]["rectangle_info"] == rectangle_info

def test_save_parameter_circle_counts_appends_to_existing_file():
    mock_param_circle_counts_new = {
        "dp=1_p1=0.4_p2=2_th=220": 15
    }
    existing_data = {
        "Outro": [
            {
                "timestamp": "2024-01-01T00:00:00",
                "parameter_combinations": {"dp=1_p1=0.4_p2=2_th=220": 5},
                "rectangle_info": {"name": "old_rect"}
            }
        ]
    }
    
    # Mock os.path.exists and json.dump/load
    with patch('os.path.exists', return_value=True), \
         patch('json.load', return_value=existing_data), \
         patch('json.dump') as mock_json_dump, \
         patch('builtins.open', MagicMock()):
        
        save_parameter_circle_counts(mock_param_circle_counts_new, BoxRectangleType.OUTRO)
        
        mock_json_dump.assert_called_once()
        args, kwargs = mock_json_dump.call_args
        saved_data = args[0]
        
        assert "Outro" in saved_data
        assert len(saved_data["Outro"]) == 2
        assert saved_data["Outro"][1]["parameter_combinations"] == mock_param_circle_counts_new
