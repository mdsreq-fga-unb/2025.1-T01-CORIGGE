#!/usr/bin/env python3
"""
Demo script to showcase parallel vs sequential circle detection performance.
This script demonstrates the speed improvements possible with parallelization.
"""

import asyncio
import time
import cv2
import numpy as np
from utils import Utils
from websocket_types import BoxRectangleType

async def demo_progress_callback(message):
    """Simple progress callback for demo"""
    print(f"[PROGRESS] {message}")

async def run_performance_comparison():
    """
    Run a performance comparison between sequential and parallel processing.
    Creates a synthetic test image with circles to benchmark performance.
    """
    
    print("🔬 Circle Detection Performance Comparison Demo")
    print("=" * 60)
    
    # Create a synthetic test image with circles
    print("📷 Creating synthetic test image with circles...")
    test_image = np.ones((2000, 3000, 3), dtype=np.uint8) * 255  # White background
    
    # Add some noise and patterns to make it more realistic
    noise = np.random.randint(0, 50, test_image.shape, dtype=np.uint8)
    test_image = cv2.subtract(test_image, noise)
    
    # Draw grid of dark circles (simulating filled answer bubbles)
    circle_radius = 25
    spacing = 80
    rows, cols = 15, 20
    
    for row in range(rows):
        for col in range(cols):
            center_x = 200 + col * spacing
            center_y = 200 + row * spacing
            # Randomly fill some circles (simulate student answers)
            if np.random.random() > 0.7:  # 30% filled
                cv2.circle(test_image, (center_x, center_y), circle_radius, (50, 50, 50), -1)  # Filled
            else:
                cv2.circle(test_image, (center_x, center_y), circle_radius, (100, 100, 100), 2)  # Empty
    
    print(f"✅ Created test image: {test_image.shape} with {rows * cols} circles in grid pattern")
    
    # Define test rectangle covering the circle area
    rectangle = {
        'x': 150 / test_image.shape[1],  # Normalized coordinates
        'y': 150 / test_image.shape[0],
        'width': (cols * spacing + 100) / test_image.shape[1],
        'height': (rows * spacing + 100) / test_image.shape[0]
    }
    
    print(f"🎯 Test rectangle: covers circle grid area")
    
    # Prepare test parameters
    test_params = {
        'rectangle': rectangle,
        'rectangle_type': BoxRectangleType.MATRICULA,
        'param2': 30,
        'dp': 1,
        'darkness_threshold': 0.7,
        'circle_size': circle_radius / test_image.shape[1],  # Normalized circle size
        'circle_precision_percentage': 1,
        'rectangle_info': {
            'name': 'performance_test',
            'index': 1,
            'total': 1,
            'page_info': 'Demo: '
        }
    }
    
    print("\n🏃 Running Sequential Processing...")
    print("-" * 40)
    
    # Test sequential processing
    from find_circles import find_circles_cv2
    
    start_time = time.time()
    
    sequential_circles = await find_circles_cv2(
        "",
        test_params['rectangle'],
        test_params['rectangle_type'],
        img=test_image,
        circle_size=test_params['circle_size'],
        dp=test_params['dp'],
        darkness_threshold=test_params['darkness_threshold'],
        circle_precision_percentage=test_params['circle_precision_percentage'],
        param2=test_params['param2'],
        on_progress=demo_progress_callback,
        rectangle_info=test_params['rectangle_info'],
        use_parallel=False  # Sequential
    )
    
    sequential_time = time.time() - start_time
    sequential_count = len(sequential_circles)
    
    print(f"✅ Sequential completed: {sequential_count} circles in {sequential_time:.2f} seconds")
    
    print("\n🚀 Running Parallel Processing...")
    print("-" * 40)
    
    # Test parallel processing
    start_time = time.time()
    
    parallel_circles = await find_circles_cv2(
        "",
        test_params['rectangle'],
        test_params['rectangle_type'],
        img=test_image,
        circle_size=test_params['circle_size'],
        dp=test_params['dp'],
        darkness_threshold=test_params['darkness_threshold'],
        circle_precision_percentage=test_params['circle_precision_percentage'],
        param2=test_params['param2'],
        on_progress=demo_progress_callback,
        rectangle_info=test_params['rectangle_info'],
        use_parallel=True,  # Parallel
        max_workers=None  # Auto-detect
    )
    
    parallel_time = time.time() - start_time
    parallel_count = len(parallel_circles)
    
    print(f"✅ Parallel completed: {parallel_count} circles in {parallel_time:.2f} seconds")
    
    # Performance analysis
    print("\n📊 Performance Analysis")
    print("=" * 60)
    print(f"Sequential Processing: {sequential_count} circles in {sequential_time:.2f}s")
    print(f"Parallel Processing:   {parallel_count} circles in {parallel_time:.2f}s")
    
    if parallel_time > 0:
        speedup = sequential_time / parallel_time
        print(f"\n🏆 Speedup: {speedup:.2f}x faster with parallel processing")
        
        if speedup > 1.5:
            print("✨ Excellent speedup! Parallel processing is significantly faster.")
        elif speedup > 1.1:
            print("✅ Good speedup! Parallel processing provides noticeable improvement.")
        else:
            print("⚠️  Limited speedup. Consider tuning parameters or check system resources.")
    
    accuracy_diff = abs(sequential_count - parallel_count)
    accuracy_percent = (1 - accuracy_diff / max(sequential_count, 1)) * 100
    print(f"🎯 Result accuracy: {accuracy_percent:.1f}% ({accuracy_diff} circle difference)")
    
    if accuracy_percent > 95:
        print("✅ Excellent accuracy! Results are nearly identical.")
    elif accuracy_percent > 90:
        print("✅ Good accuracy! Minor differences in detection.")
    else:
        print("⚠️  Accuracy concern. Check parallel implementation.")
    
    print(f"\n💡 Tips for optimization:")
    print(f"   - CPU cores available: {cv2.getNumberOfCPUs()}")
    print(f"   - For large images: Enable parallel processing")
    print(f"   - For many rectangles: Use rectangle-level parallelization") 
    print(f"   - For few rectangles: Use parameter-level parallelization")
    
    return {
        'sequential_time': sequential_time,
        'parallel_time': parallel_time,
        'speedup': sequential_time / parallel_time if parallel_time > 0 else 0,
        'sequential_circles': sequential_count,
        'parallel_circles': parallel_count,
        'accuracy': accuracy_percent
    }

async def demo_multiple_rectangles():
    """
    Demo for rectangle-level parallelization with multiple detection areas.
    """
    print("\n🔬 Multiple Rectangle Parallel Processing Demo")
    print("=" * 60)
    
    # Create test image with multiple distinct areas
    test_image = np.ones((1500, 2000, 3), dtype=np.uint8) * 255
    
    # Create multiple rectangle areas with different circle patterns
    rectangles_data = []
    
    # Area 1: Dense grid (student ID)
    for row in range(8):
        for col in range(10):
            center_x = 100 + col * 40
            center_y = 100 + row * 40
            if np.random.random() > 0.8:  # 20% filled
                cv2.circle(test_image, (center_x, center_y), 15, (60, 60, 60), -1)
            else:
                cv2.circle(test_image, (center_x, center_y), 15, (120, 120, 120), 2)
    
    rectangles_data.append({
        'box_id': 'student_id',
        'rect': {'x': 50/2000, 'y': 50/1500, 'width': 450/2000, 'height': 350/1500},
        'rect_type': BoxRectangleType.MATRICULA,
        'rectangle_info': {'name': 'Student_ID', 'index': 1, 'total': 3}
    })
    
    # Area 2: Multiple choice questions (sparse)
    for row in range(10):
        for col in range(4):
            center_x = 700 + col * 60
            center_y = 200 + row * 50
            if np.random.random() > 0.75:  # 25% filled
                cv2.circle(test_image, (center_x, center_y), 20, (40, 40, 40), -1)
            else:
                cv2.circle(test_image, (center_x, center_y), 20, (100, 100, 100), 2)
    
    rectangles_data.append({
        'box_id': 'questions_1_10',
        'rect': {'x': 650/2000, 'y': 150/1500, 'width': 300/2000, 'height': 550/1500},
        'rect_type': BoxRectangleType.MATRICULA,
        'rectangle_info': {'name': 'Questions_1-10', 'index': 2, 'total': 3}
    })
    
    # Area 3: True/False section
    for row in range(15):
        for col in range(2):
            center_x = 1200 + col * 80
            center_y = 150 + row * 40
            if np.random.random() > 0.6:  # 40% filled
                cv2.circle(test_image, (center_x, center_y), 18, (50, 50, 50), -1)
            else:
                cv2.circle(test_image, (center_x, center_y), 18, (110, 110, 110), 2)
    
    rectangles_data.append({
        'box_id': 'true_false',
        'rect': {'x': 1150/2000, 'y': 100/1500, 'width': 200/2000, 'height': 650/1500},
        'rect_type': BoxRectangleType.MATRICULA,
        'rectangle_info': {'name': 'True_False', 'index': 3, 'total': 3}
    })
    
    print(f"✅ Created test image with {len(rectangles_data)} distinct rectangle areas")
    
    # Test rectangle-level parallelization
    job_params = {
        'circle_size': 18 / test_image.shape[1],
        'dp': 1,
        'darkness_threshold': 0.7,
        'circle_precision_percentage': 1,
        'param2': 30
    }
    
    print("\n🚀 Testing Rectangle-Level Parallel Processing...")
    
    try:
        from find_circles_parallel import find_circles_multiple_rectangles_parallel
        
        start_time = time.time()
        
        results = await find_circles_multiple_rectangles_parallel(
            test_image,
            rectangles_data,
            job_params,
            on_progress=demo_progress_callback,
            max_rectangle_workers=None  # Auto-configure
        )
        
        parallel_rect_time = time.time() - start_time
        
        print(f"\n✅ Rectangle-level parallel processing completed in {parallel_rect_time:.2f} seconds")
        print("\n📊 Results by rectangle:")
        
        total_circles = 0
        for box_id, circles in results.items():
            circle_count = len(circles)
            total_circles += circle_count
            rect_data = next((r for r in rectangles_data if r['box_id'] == box_id), {})
            rect_name = rect_data.get('rectangle_info', {}).get('name', box_id)
            print(f"   {rect_name}: {circle_count} circles")
        
        print(f"\n🎯 Total circles detected: {total_circles}")
        print(f"⚡ Processing rate: {total_circles / parallel_rect_time:.1f} circles/second")
        
    except ImportError:
        print("❌ Rectangle-level parallelization not available")
    
if __name__ == "__main__":
    # Enable logging for demo
    import sys
    import logging
    
    # Setup basic logging to see progress
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    
    print("🚀 Starting Circle Detection Parallelization Demo")
    print("This demo will compare sequential vs parallel processing performance.\n")
    
    async def main():
        try:
            # Run basic performance comparison
            results = await run_performance_comparison()
            
            # Run rectangle-level parallelization demo
            await demo_multiple_rectangles()
            
            print("\n🎉 Demo completed successfully!")
            print(f"📈 Final speedup achieved: {results['speedup']:.2f}x")
            
        except Exception as e:
            print(f"❌ Demo failed: {e}")
            import traceback
            traceback.print_exc()
    
    # Run the demo
    asyncio.run(main()) 