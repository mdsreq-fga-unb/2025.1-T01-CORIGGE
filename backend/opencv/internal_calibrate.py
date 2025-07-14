import cv2 as cv2
import numpy as np
from PIL import Image
from pdf2image import convert_from_path
from utils import Utils,FlagNames


def auto_crop_document(img, padding_percent=0.005):
    """
    Automatically crop a scanned document to remove empty white spaces.
    
    Args:
        img: PIL Image or OpenCV image
        padding_percent: Percentage of padding to add around detected content (0.02 = 2%)
    
    Returns:
        Cropped PIL Image
    """
    # Convert PIL Image to OpenCV format if needed
    if isinstance(img, Image.Image):
        cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
        original_pil = img
    else:
        cv_img = img
        original_pil = Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    
    # Show original image
    # if Utils.is_debug():
    #     show_image(cv_img, "crop_1_original_image")
    
    # Get original dimensions
    height, width = cv_img.shape[:2]
    
    # Convert to grayscale
    gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)
    # if Utils.is_debug():
    #     show_image(gray, "crop_2_grayscale")
    
    # Apply Gaussian blur to reduce noise
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    # if Utils.is_debug():
    #     show_image(blurred, "crop_3_blurred")
    
    # Use adaptive threshold to handle varying lighting conditions
    thresh = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, 
                                   cv2.THRESH_BINARY_INV, 11, 10)
    
    
    
    # Find contours
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    
    if not contours:
        Utils.log_info("No contours found, returning original image")
        return original_pil
    
    # Show contours
    contour_img = cv_img.copy()
    cv2.drawContours(contour_img, contours, -1, (0, 255, 0), 2)
    # if Utils.is_debug():
    #     show_image(contour_img, "crop_5_all_contours")
    
    # Method 1: Find the largest contour (main document)
    largest_contour = max(contours, key=cv2.contourArea)
    
    # Show largest contour
    largest_contour_img = cv_img.copy()
    cv2.drawContours(largest_contour_img, [largest_contour], -1, (0, 0, 255), 3)
    # if Utils.is_debug():
    #     show_image(largest_contour_img, "crop_6_largest_contour")
    
    # Get bounding rectangle of the largest contour
    x, y, w, h = cv2.boundingRect(largest_contour)
    
    # Method 2: Alternative approach - find bounding box of all non-white pixels
    # This is more robust for documents with multiple separate elements
    coords = np.column_stack(np.where(thresh > 0))
    if len(coords) > 0:
        y_min, x_min = coords.min(axis=0)
        y_max, x_max = coords.max(axis=0)
        
        # Use whichever method gives a more reasonable result
        contour_area = w * h
        coords_area = (x_max - x_min) * (y_max - y_min)
        
        # Show both bounding boxes for comparison
        comparison_img = cv_img.copy()
        # Contour-based box in blue
        cv2.rectangle(comparison_img, (x, y), (x + w, y + h), (255, 0, 0), 2)
        # Coordinate-based box in green
        cv2.rectangle(comparison_img, (x_min, y_min), (x_max, y_max), (0, 255, 0), 2)
        # if Utils.is_debug():
        #     show_image(comparison_img, "crop_7_bounding_boxes_comparison")
        
        # If the coordinate-based method gives a significantly larger area, use it
        if coords_area > contour_area * 1.2:
            x, y, w, h = x_min, y_min, x_max - x_min, y_max - y_min
            Utils.log_info(f"Using coordinate-based bounding box (larger area)")
        else:
            Utils.log_info(f"Using contour-based bounding box")
    
    # Add padding
    padding_x = int(width * padding_percent)
    padding_y = int(height * padding_percent)
    
    # Expand the crop area with padding, but keep within image bounds
    x = max(0, x - padding_x)
    y = max(0, y - padding_y)
    w = min(width - x, w + 2 * padding_x)
    h = min(height - y, h + 2 * padding_y)
    
    # Ensure minimum reasonable size (at least 50% of original)
    min_width = int(width * 0.5)
    min_height = int(height * 0.5)
    
    if w < min_width or h < min_height:
        Utils.log_info("Detected crop area too small, returning original image")
        # if Utils.is_debug():
        #     show_image(cv_img, "crop_8_no_crop_too_small")
        return original_pil
    
    # Draw the final crop rectangle on the image
    debug_img = cv_img.copy()
    cv2.rectangle(debug_img, (x, y), (x + w, y + h), (0, 255, 255), 4)  # Yellow rectangle
    cv2.putText(debug_img, f"CROP AREA: {w}x{h}", (x, y-10), 
                cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
    # if Utils.is_debug():
    #     show_image(debug_img, "crop_8_final_crop_area")
    
    Utils.log_info(f"Cropping from ({x}, {y}) with size ({w}, {h})")
    Utils.log_info(f"Original size: ({width}, {height}), New size: ({w}, {h})")
    Utils.log_info(f"Size reduction: {((width * height - w * h) / (width * height) * 100):.1f}%")
    
    # Crop the original PIL image
    cropped_pil = original_pil.crop((x, y, x + w, y + h))
    

    cropped_cv = cv2.cvtColor(np.array(cropped_pil), cv2.COLOR_RGB2BGR)
    # if Utils.is_debug():
    #     show_image(cropped_cv, "crop_9_final_cropped_result")
    
    return cropped_pil


def detect_document_corners(img):
    """
    Simplified method: Detect the four corners of a document using darkest pixels.
    Gets pixels with values 0-30 and finds the 4 most distant from center and each other.
    Returns the four corner points for perspective correction.
    """
    # Convert PIL Image to OpenCV format if needed
    if isinstance(img, Image.Image):
        cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    else:
        cv_img = img
    
    if Utils.get_image_show_flag(FlagNames.CornerDetection):
        show_image(cv_img, "corners_0_original")
    
    # Convert to grayscale
    gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)
    
    if Utils.get_image_show_flag(FlagNames.CornerDetection):
        show_image(gray, "corners_1_grayscale")
    
    # Get image dimensions and center
    height, width = gray.shape
    center = np.array([width // 2, height // 2])
    
    # Apply threshold to get only the darkest pixels (0-30)
    _, thresh = cv2.threshold(gray, 70, 255, cv2.THRESH_BINARY_INV)
    
    if Utils.get_image_show_flag(FlagNames.CornerDetection):
        show_image(thresh, "corners_2_threshold")
    
    # Show original image with threshold overlay
    if Utils.get_image_show_flag(FlagNames.CornerDetection):
        overlay_img = cv_img.copy()
        overlay_img[thresh > 0] = [0, 0, 255]  # Mark dark pixels in red
        show_image(overlay_img, "corners_2_dark_pixels_overlay")
    
    # Find all dark pixels
    dark_pixels = np.column_stack(np.where(thresh > 0))
    
    if len(dark_pixels) == 0:
        Utils.log_info("No dark pixels found for corner detection")
        return None
    
    # Convert to (x, y) format for easier processing
    dark_pixels_xy = np.array([(pt[1], pt[0]) for pt in dark_pixels])
    
    Utils.log_info(f"Found {len(dark_pixels_xy)} dark pixels")
    
    # Show center point
    if Utils.get_image_show_flag(FlagNames.CornerDetection):
        center_img = cv_img.copy()
        cv2.circle(center_img, tuple(center.astype(int)), 20, (0, 255, 0), 3)  # Green circle for center
        cv2.putText(center_img, "CENTER", tuple((center + 30).astype(int)), 
                   cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
        show_image(center_img, "corners_2_center_point")
    
    # Find the 4 pixels with maximum distance from center and between themselves
    corners, angle = find_4_most_distant_pixels(dark_pixels_xy, center, cv_img)
    
    if corners is None:
        Utils.log_info("Could not find 4 suitable corner pixels")
        return None
    
    # Validate the corners
    score = validate_document_corners(corners, cv_img.shape)
    Utils.log_info(f"Corner validation score: {score:.3f}")
    Utils.log_info(f"Rectangle angle from 4 most distant pixels: {angle:.2f}°")
    

    Utils.log_info(f"Corners accepted with score: {score:.3f}, angle: {angle:.2f}°")
    
    if Utils.get_image_show_flag(FlagNames.CornerDetection):
        debug_img = cv_img.copy()
        
        # Draw the 4 corners with different colors
        colors = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)]  # Blue, Green, Red, Yellow
        for j, corner in enumerate(corners):
            cv2.circle(debug_img, tuple(corner.astype(int)), 15, colors[j], -1)
            cv2.putText(debug_img, str(j+1), tuple((corner + 20).astype(int)), 
                        cv2.FONT_HERSHEY_SIMPLEX, 1, colors[j], 2)
        
        # Draw the minimum area rectangle
        corners_int = corners.astype(np.int32)
        rect = cv2.minAreaRect(corners_int)
        box = cv2.boxPoints(rect)
        box = np.int32(box)
        cv2.drawContours(debug_img, [box], 0, (0, 255, 255), 3)  # Yellow rectangle
        
        # Add angle and validation info
        cv2.putText(debug_img, f"Angle: {angle:.1f}°", (10, 30), 
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
        cv2.putText(debug_img, f"Validation Score: {score:.3f}", (10, 70), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
        cv2.putText(debug_img, "ACCEPTED", (10, 110), 
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
        
        show_image(debug_img, "corners_6_final_accepted")
    
    return order_corners(corners)
    

    


def validate_document_corners(corners, img_shape):
    """
    Validate detected corners to ensure they form a reasonable document rectangle.
    Returns a score between 0 and 1 (higher is better).
    Enhanced with stricter validation to prevent false positives.
    """
    if len(corners) != 4:
        return 0
    
    h, w = img_shape[:2]
    score = 0
    
    # Check if corners are within image bounds
    if np.all(corners >= 0) and np.all(corners[:, 0] < w) and np.all(corners[:, 1] < h):
        score += 0.15  # Reduced weight
    else:
        return 0  # Invalid if any corner is outside image
    
    # Calculate area of the quadrilateral
    area = cv2.contourArea(corners)
    img_area = w * h
    area_ratio = area / img_area
    
    # Much stricter area requirements - should be substantial portion of image
    if 0.3 <= area_ratio <= 0.95:  # At least 30% of image
        score += 0.25 * min(area_ratio / 0.7, (1 - area_ratio) / 0.05)
    elif area_ratio < 0.3:
        Utils.log_info(f"Corner area too small: {area_ratio:.3f} (need >= 0.3)")
        return 0  # Reject small areas completely
    
    # Check if the quadrilateral is approximately rectangular
    # Calculate all side lengths
    ordered = order_corners(corners)
    sides = []
    for i in range(4):
        p1 = ordered[i]
        p2 = ordered[(i + 1) % 4]
        sides.append(np.linalg.norm(p2 - p1))
    
    # Opposite sides should be similar - stricter requirement
    top_bottom_ratio = min(sides[0], sides[2]) / max(sides[0], sides[2])
    left_right_ratio = min(sides[1], sides[3]) / max(sides[1], sides[3])
    
    # Require at least 70% similarity for opposite sides
    if top_bottom_ratio < 0.7 or left_right_ratio < 0.7:
        Utils.log_info(f"Sides not rectangular enough: TB={top_bottom_ratio:.3f}, LR={left_right_ratio:.3f}")
        return 0
    
    score += 0.25 * (top_bottom_ratio + left_right_ratio) / 2
    
    # Check angles (should be close to 90 degrees) - stricter requirements
    angles = []
    for i in range(4):
        p1 = ordered[(i - 1) % 4]
        p2 = ordered[i]
        p3 = ordered[(i + 1) % 4]
        
        v1 = p1 - p2
        v2 = p3 - p2
        
        cos_angle = np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2))
        angle = np.arccos(np.clip(cos_angle, -1, 1))
        angle_deg = np.degrees(angle)
        angles.append(abs(angle_deg - 90))  # Deviation from 90 degrees in degrees
    
    avg_angle_deviation = np.mean(angles)
    max_angle_deviation = np.max(angles)
    
    # Stricter angle requirements
    if avg_angle_deviation > 25 or max_angle_deviation > 40:  # Max 25° average, 40° individual deviation
        Utils.log_info(f"Angles not rectangular: avg={avg_angle_deviation:.1f}°, max={max_angle_deviation:.1f}°")
        return 0
    
    angle_score = max(0, 1 - (avg_angle_deviation / 25))  # Normalize to 0-1
    score += 0.2 * angle_score
    
    # Add aspect ratio check - documents typically have reasonable aspect ratios
    width_estimate = (sides[0] + sides[2]) / 2
    height_estimate = (sides[1] + sides[3]) / 2
    aspect_ratio = max(width_estimate, height_estimate) / min(width_estimate, height_estimate)
    
    # Reasonable aspect ratio (1:1 to 3:1)
    if aspect_ratio <= 3.0:
        aspect_score = max(0, 1 - (aspect_ratio - 1) / 2)  # Best score at 1:1, decreasing to 3:1
        score += 0.15 * aspect_score
    else:
        Utils.log_info(f"Aspect ratio too extreme: {aspect_ratio:.2f}")
        return 0
    
    Utils.log_info(f"Corner validation details: area={area_ratio:.3f}, TB={top_bottom_ratio:.3f}, "
                   f"LR={left_right_ratio:.3f}, angles={avg_angle_deviation:.1f}°, aspect={aspect_ratio:.2f}")
    
    return score


def find_4_most_distant_pixels(pixels, center, cv_img=None):
    """
    Find 4 pixels that are most distant from center and have good separation between themselves.
    Uses a greedy approach to select pixels that maximize both center distance and mutual distance.
    Returns the corners and the angle of the rectangle formed by these pixels.
    """
    if len(pixels) < 4:
        return None, None
    
    # Calculate distances from center for all pixels
    center_distances = np.linalg.norm(pixels - center, axis=1)
    
    # Sort pixels by distance from center (descending)
    sorted_indices = np.argsort(center_distances)[::-1]
    
    # Start with the pixel most distant from center
    selected_pixels = [pixels[sorted_indices[0]]]
    selected_indices = [sorted_indices[0]]
    
    Utils.log_info(f"Starting with pixel at distance {center_distances[sorted_indices[0]]:.1f} from center")
    
    # Show first selected pixel
    if Utils.get_image_show_flag(FlagNames.CornerDetection) and cv_img is not None:
        first_pixel_img = cv_img.copy()
        first_pixel = selected_pixels[0].astype(int)
        cv2.circle(first_pixel_img, tuple(first_pixel), 15, (255, 0, 0), -1)  # Blue circle
        cv2.putText(first_pixel_img, "1", tuple(first_pixel + 20), 
                   cv2.FONT_HERSHEY_SIMPLEX, 1, (255, 0, 0), 2)
        cv2.putText(first_pixel_img, f"Distance: {center_distances[sorted_indices[0]]:.1f}", (10, 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 0, 0), 2)
        show_image(first_pixel_img, "corners_3_first_pixel")
    
    # Greedily select remaining 3 pixels
    for _ in range(3):
        best_pixel = None
        best_score = -1
        best_idx = -1
        
        # Try remaining pixels
        for idx in sorted_indices:
            if idx in selected_indices:
                continue
                
            candidate_pixel = pixels[idx]
            
            # Calculate score: combination of distance from center and minimum distance to selected pixels
            center_dist = center_distances[idx]
            
            # Find minimum distance to already selected pixels
            min_dist_to_selected = float('inf')
            for selected_pixel in selected_pixels:
                dist = np.linalg.norm(candidate_pixel - selected_pixel)
                min_dist_to_selected = min(min_dist_to_selected, dist)
            
            # Score combines center distance and separation from selected pixels
            # Normalize both components to similar scales
            max_center_dist = np.max(center_distances)
            normalized_center_dist = center_dist / max_center_dist
            
            # Estimate maximum possible distance between pixels (diagonal of image)
            img_diagonal = np.linalg.norm(center * 2)  # rough estimate
            normalized_separation = min_dist_to_selected / img_diagonal
            
            # Combined score: weight center distance and separation equally
            score = normalized_center_dist * 0.5 + normalized_separation * 0.5
            
            if score > best_score:
                best_score = score
                best_pixel = candidate_pixel
                best_idx = idx
        
        if best_pixel is not None:
            selected_pixels.append(best_pixel)
            selected_indices.append(best_idx)
            Utils.log_info(f"Selected pixel {len(selected_pixels)} with score {best_score:.3f}")
            
            # Show current selection
            if Utils.get_image_show_flag(FlagNames.CornerDetection) and cv_img is not None:
                selection_img = cv_img.copy()
                for i, pixel in enumerate(selected_pixels):
                    color = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)][i]  # Blue, Green, Red, Yellow
                    cv2.circle(selection_img, tuple(pixel.astype(int)), 15, color, -1)
                    cv2.putText(selection_img, str(i+1), tuple((pixel + 20).astype(int)), 
                               cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2)
                cv2.putText(selection_img, f"Selected: {len(selected_pixels)}/4", (10, 30), 
                           cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
                show_image(selection_img, f"corners_4_selection_{len(selected_pixels)}")
        else:
            Utils.log_info("Could not find suitable pixel")
            return None, None
    
    # Convert to numpy array
    corners = np.array(selected_pixels, dtype=np.float32)
    
    # Verify we have 4 distinct points
    if len(corners) != 4:
        Utils.log_info("Failed to find 4 distinct corners")
        return None, None
    
    # Check that corners are reasonably spread out
    min_distance = float('inf')
    for i in range(4):
        for j in range(i + 1, 4):
            dist = np.linalg.norm(corners[i] - corners[j])
            min_distance = min(min_distance, dist)
    
    # Minimum distance should be at least 10% of image diagonal
    img_diagonal = np.linalg.norm(center * 2)
    min_required_distance = img_diagonal * 0.1
    
    if min_distance < min_required_distance:
        Utils.log_info(f"Corners too close together: min_distance={min_distance:.1f}, required={min_required_distance:.1f}")
        return None, None
    
    # Create a rectangle from the 4 corners and get the angle
    corners_int = corners.astype(np.int32)
    rect = cv2.minAreaRect(corners_int)
    
    # Extract the angle from the rectangle
    angle = rect[2]
    width, height = rect[1]
    
    Utils.log_info(f"Raw angle from minAreaRect: {angle:.2f}°, dimensions: {width:.1f}x{height:.1f}")
    
    # Adjust angle based on rectangle orientation
    if width > height:
        # Landscape orientation
        if angle < -45:
            angle = 90 + angle
    else:
        # Portrait orientation  
        if angle < -45:
            angle = 90 + angle
        else:
            angle = angle
    
    # Limit the angle to reasonable rotation range
    if abs(angle) > 45:
        if angle > 0:
            angle = angle - 90
        else:
            angle = angle + 90
    
    Utils.log_info(f"Adjusted angle: {angle:.2f}°")
    Utils.log_info(f"Successfully found 4 corners with minimum separation: {min_distance:.1f}")
    
    # Show final rectangle and angle
    if Utils.get_image_show_flag(FlagNames.CornerDetection) and cv_img is not None:
        final_img = cv_img.copy()
        
        # Draw the 4 corners
        for i, corner in enumerate(corners):
            color = [(255, 0, 0), (0, 255, 0), (0, 0, 255), (255, 255, 0)][i]  # Blue, Green, Red, Yellow
            cv2.circle(final_img, tuple(corner.astype(int)), 15, color, -1)
            cv2.putText(final_img, str(i+1), tuple((corner + 20).astype(int)), 
                       cv2.FONT_HERSHEY_SIMPLEX, 1, color, 2)
        
        # Draw the minimum area rectangle
        rect = cv2.minAreaRect(corners_int)
        box = cv2.boxPoints(rect)
        box = np.int32(box)
        cv2.drawContours(final_img, [box], 0, (0, 255, 255), 3)  # Yellow rectangle
        
        # Add angle information
        cv2.putText(final_img, f"Angle: {angle:.1f}°", (10, 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
        cv2.putText(final_img, f"Min Separation: {min_distance:.1f}", (10, 70), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 255), 2)
        
        show_image(final_img, "corners_5_final_rectangle")
    
    return corners, angle


def order_corners(corners):
    """
    Order corners in a consistent way: top-left, top-right, bottom-right, bottom-left.
    """
    # Sort by Y coordinate (top to bottom)
    corners = corners[np.argsort(corners[:, 1])]
    
    # Get top two and bottom two points
    top_two = corners[:2]
    bottom_two = corners[2:]
    
    # Sort top two by X coordinate (left to right)
    top_two = top_two[np.argsort(top_two[:, 0])]
    
    # Sort bottom two by X coordinate (left to right)
    bottom_two = bottom_two[np.argsort(bottom_two[:, 0])]
    
    # Return in order: top-left, top-right, bottom-right, bottom-left
    return np.array([top_two[0], top_two[1], bottom_two[1], bottom_two[0]], dtype=np.float32)


def detect_contour_angle(img):
    """
    Detect the rotation angle using the blackest parts of the image.
    Uses percentile-based method to ignore outliers and find main content bounds.
    Returns both angle and the bounding rectangle.
    """
    # Convert PIL Image to OpenCV format if needed
    if isinstance(img, Image.Image):
        cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    else:
        cv_img = img
    
    # Convert to grayscale
    gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)
    
    # Apply Gaussian blur to reduce noise
    blurred = cv2.GaussianBlur(gray, (3, 3), 0)
    
    # Create aggressive threshold to get only the blackest parts (text/content)
    # Use a lower threshold value to capture only the darkest pixels
    _, thresh = cv2.threshold(blurred, 60, 255, cv2.THRESH_BINARY_INV)
    
    # Apply morphological operations to connect nearby text
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (3, 3))
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
    
    # Find all black pixels (text/content pixels)
    black_pixels = np.column_stack(np.where(thresh > 0))
    
    if len(black_pixels) == 0:
        Utils.log_info("No black pixels found for angle detection, returning 0")
        return 0, None
    
    Utils.log_info(f"Total black pixels found: {len(black_pixels)}")
    
    # Try different percentile values if the first one doesn't work well
    percentile_options = [1, 3, 5, 8]  # Less aggressive options
    angle = 0
    crop_rect = None
    filtered_pixels_xy = None
    
    for percentile in percentile_options:
        Utils.log_info(f"Trying percentile: {percentile}%")
        
        y_coords = black_pixels[:, 0]
        x_coords = black_pixels[:, 1]
        
        # Calculate percentile-based bounds to ignore outliers
        y_min_percentile = int(np.percentile(y_coords, percentile))
        y_max_percentile = int(np.percentile(y_coords, 100 - percentile))
        x_min_percentile = int(np.percentile(x_coords, percentile))
        x_max_percentile = int(np.percentile(x_coords, 100 - percentile))
        
        # Filter black pixels to only those within percentile bounds
        mask = ((y_coords >= y_min_percentile) & (y_coords <= y_max_percentile) & 
                (x_coords >= x_min_percentile) & (x_coords <= x_max_percentile))
        
        filtered_black_pixels = black_pixels[mask]
        
        Utils.log_info(f"Filtered pixels with {percentile}% percentile: {len(filtered_black_pixels)} (kept {len(filtered_black_pixels)/len(black_pixels)*100:.1f}%)")
        
        if len(filtered_black_pixels) < 100:  # Need minimum pixels for reliable angle detection
            Utils.log_info(f"Not enough filtered pixels ({len(filtered_black_pixels)}), trying next percentile")
            continue
        
        # Convert to (x, y) format for minimum area rectangle
        filtered_pixels_xy = np.array([(pt[1], pt[0]) for pt in filtered_black_pixels], dtype=np.int32)
        
        # Get the minimum area rectangle that fits the filtered pixels
        rect = cv2.minAreaRect(filtered_pixels_xy)
        
        # Extract the angle from the rectangle
        angle = rect[2]
        
        # Get the dimensions of the rectangle
        width, height = rect[1]
        
        Utils.log_info(f"Raw angle from minAreaRect: {angle:.2f}°, dimensions: {width:.1f}x{height:.1f}")
        
        # Adjust angle based on rectangle orientation
        if width > height:
            # Landscape orientation
            if angle < -45:
                angle = 90 + angle
        else:
            # Portrait orientation  
            if angle < -45:
                angle = 90 + angle
            else:
                angle = angle
        
        # Limit the angle to reasonable rotation range
        if abs(angle) > 45:
            if angle > 0:
                angle = angle - 90
            else:
                angle = angle + 90
        
        Utils.log_info(f"Adjusted angle: {angle:.2f}°")
        
        # If we got a reasonable angle (not exactly 0), use this result
        if abs(angle) > 0.5:  # More than 0.5 degrees
            Utils.log_info(f"Found good angle {angle:.2f}° with {percentile}% percentile")
            
            # Get the bounding rectangle coordinates using percentile bounds
            x_min, x_max = x_min_percentile, x_max_percentile
            y_min, y_max = y_min_percentile, y_max_percentile
            
            # Add some padding (0.2% of image dimensions)
            img_height, img_width = cv_img.shape[:2]
            padding_x = int(img_width * 0.002)
            padding_y = int(img_height * 0.002)
            
            # Apply padding but keep within image bounds
            crop_rect = {
                'x': max(0, x_min - padding_x),
                'y': max(0, y_min - padding_y),
                'width': min(img_width - max(0, x_min - padding_x), (x_max - x_min) + 2 * padding_x),
                'height': min(img_height - max(0, y_min - padding_y), (y_max - y_min) + 2 * padding_y)
            }
            
            break
    
    # If we still don't have a good result, fall back to simple bounding box
    if abs(angle) <= 0.5 or crop_rect is None:
        Utils.log_info("Percentile method failed, falling back to simple bounding box")
        
        # Use all black pixels for bounding box
        y_coords = black_pixels[:, 0]
        x_coords = black_pixels[:, 1]
        
        x_min, x_max = np.min(x_coords), np.max(x_coords)
        y_min, y_max = np.min(y_coords), np.max(y_coords)
        
        # Add padding
        img_height, img_width = cv_img.shape[:2]
        padding_x = int(img_width * 0.002)
        padding_y = int(img_height * 0.002)
        
        crop_rect = {
            'x': max(0, x_min - padding_x),
            'y': max(0, y_min - padding_y),
            'width': min(img_width - max(0, x_min - padding_x), (x_max - x_min) + 2 * padding_x),
            'height': min(img_height - max(0, y_min - padding_y), (y_max - y_min) + 2 * padding_y)
        }
        
        # Try to get angle from all pixels as fallback
        all_pixels_xy = np.array([(pt[1], pt[0]) for pt in black_pixels], dtype=np.int32)
        rect = cv2.minAreaRect(all_pixels_xy)
        angle = rect[2]
        width, height = rect[1]
        
        # Apply same angle adjustments
        if width > height:
            if angle < -45:
                angle = 90 + angle
        else:
            if angle < -45:
                angle = 90 + angle
        
        if abs(angle) > 45:
            if angle > 0:
                angle = angle - 90
            else:
                angle = angle + 90
                
        Utils.log_info(f"Fallback angle: {angle:.2f}°")
    
    # Draw visualization for debugging
    """ if Utils.is_debug() and filtered_pixels_xy is not None:
        debug_img = cv_img.copy()
        
        # Draw all filtered black pixels in blue (sample to avoid clutter)
        if len(filtered_pixels_xy) > 1000:
            sample_indices = np.random.choice(len(filtered_pixels_xy), 1000, replace=False)
            sample_pixels = filtered_pixels_xy[sample_indices]
        else:
            sample_pixels = filtered_pixels_xy
            
        for pt in sample_pixels:
            cv2.circle(debug_img, (int(pt[0]), int(pt[1])), 1, (255, 0, 0), -1)
        
        # Draw the minimum area rectangle in green
        rect = cv2.minAreaRect(filtered_pixels_xy)
        box = cv2.boxPoints(rect)
        box = np.int32(box)
        cv2.drawContours(debug_img, [box], 0, (0, 255, 0), 3)
        
        # Draw the crop rectangle in yellow
        cv2.rectangle(debug_img, (crop_rect['x'], crop_rect['y']), 
                     (crop_rect['x'] + crop_rect['width'], crop_rect['y'] + crop_rect['height']), 
                     (0, 255, 255), 3)
        
        # Add text info
        cv2.putText(debug_img, f"Angle: {angle:.1f}°", (10, 30), 
                    cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
        cv2.putText(debug_img, f"Filtered pixels: {len(filtered_pixels_xy)}", (10, 70), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 0, 0), 2)
        cv2.putText(debug_img, f"Total pixels: {len(black_pixels)}", (10, 110), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 0, 0), 2)
        cv2.putText(debug_img, f"Rect: {width:.0f}x{height:.0f}", (10, 150), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
        cv2.putText(debug_img, f"Crop: {crop_rect['width']}x{crop_rect['height']}", (10, 190), 
                    cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 255), 2)
        
        show_image(debug_img, "2_percentile_based_angle_detection") """
    
    Utils.log_info(f"Final detected angle using percentile-based method: {angle:.1f}°")
    Utils.log_info(f"Crop rectangle: {crop_rect}")
    
    return angle, crop_rect


def normalize_image_brightness(img):
    """
    Normalize image brightness using dynamic range stretching and gamma correction.
    Stretches the histogram to use the full 0-255 range, then applies gamma correction.
    """
    # Convert PIL Image to OpenCV format if needed
    if isinstance(img, Image.Image):
        cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
        was_pil = True
    else:
        cv_img = img
        was_pil = False
    
    # Show original for comparison
    # if Utils.is_debug():
    #     show_image(cv_img, "norm_0_original_before_normalization")
    
    # Convert to grayscale for analysis
    gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)
    
    # Step 1: Dynamic Range Normalization - stretch histogram to use full 0-255 range
    min_val = np.min(gray)
    max_val = np.max(gray)
    
    if max_val > min_val:  # Avoid division by zero
        # Apply to all channels
        for i in range(3):
            cv_img[:, :, i] = ((cv_img[:, :, i] - min_val) / (max_val - min_val) * 255).astype(np.uint8)
        
        # if Utils.is_debug():
        #     show_image(cv_img, "norm_1_range_stretched")
        Utils.log_info(f"Dynamic range: {min_val}-{max_val} → 0-255")
    else:
        Utils.log_info("Image has no dynamic range to stretch")
    
    # Step 2: Gamma Correction
    # Adjust overall brightness based on image characteristics
    mean_brightness = np.mean(cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY))
    
    if mean_brightness < 100:  # Too dark
        gamma = 0.7  # Brighten
        Utils.log_info(f"Image too dark (mean: {mean_brightness:.1f}), applying gamma: {gamma}")
    elif mean_brightness > 180:  # Too bright  
        gamma = 1.3  # Darken
        Utils.log_info(f"Image too bright (mean: {mean_brightness:.1f}), applying gamma: {gamma}")
    else:
        gamma = 1.0  # No gamma correction needed
        Utils.log_info(f"Image brightness OK (mean: {mean_brightness:.1f}), no gamma correction")
    
    if gamma != 1.0:
        # Build gamma correction lookup table
        inv_gamma = 1.0 / gamma
        table = np.array([((i / 255.0) ** inv_gamma) * 255 for i in np.arange(0, 256)]).astype("uint8")
        cv_img = cv2.LUT(cv_img, table)
        
        # if Utils.is_debug():
        #     show_image(cv_img, f"norm_2_gamma_corrected_{gamma}")
    
    # if Utils.is_debug():
    #     # Show before/after comparison
    #     original_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR) if was_pil else img
    #     comparison = np.hstack((original_img, cv_img))
    #     show_image(comparison, "norm_3_before_after_comparison")
    
    # Convert back to PIL if input was PIL
    if was_pil:
        result = Image.fromarray(cv2.cvtColor(cv_img, cv2.COLOR_BGR2RGB))
        return result
    else:
        return cv_img


def apply_calibration_to_image(img: Image, padding_percent=0.005):
    # Show original image
    # if Utils.is_debug():
    #     cv_original = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    #     show_image(cv_original, "0_original_input")
    
    # First, normalize brightness and contrast to handle varying lighting
    normalized_img = normalize_image_brightness(img)
    Utils.log_info("Applied brightness and contrast normalization")
    
    # Show normalized image
    # if Utils.is_debug():
    #     cv_normalized = cv2.cvtColor(np.array(normalized_img), cv2.COLOR_RGB2BGR)
    #     show_image(cv_normalized, "1_after_normalization")
    
    # Convert PIL Image to OpenCV format
    cv_img = cv2.cvtColor(np.array(normalized_img), cv2.COLOR_RGB2BGR)


    # Detect rotation angle using document corners
    transform_info = detect_shear_and_perspective(cv_img)
    
    method = transform_info.get('method', 'unknown')
    Utils.log_info(f"Using rotation correction ({transform_info['angle']:.1f}°) via {method}")
    
    # Add padding to the crop_rect for rotation correction
    if transform_info['crop_rect'] is not None:
        crop_rect = transform_info['crop_rect']
        crop_rect['x'] = crop_rect['x'] - padding_percent * crop_rect['width']
        crop_rect['y'] = crop_rect['y'] - padding_percent * crop_rect['height']
        crop_rect['width'] = crop_rect['width'] + 2 * padding_percent * crop_rect['width']
        crop_rect['height'] = crop_rect['height'] + 2 * padding_percent * crop_rect['height']
        transform_info['crop_rect'] = crop_rect
    
    # Apply rotation correction
    height, width = cv_img.shape[:2]
    center = (width // 2, height // 2)
    
    # Get rotation matrix
    M = cv2.getRotationMatrix2D(center, transform_info['angle'], 1.0)

    # if Utils.is_debug():
    #     show_image(cv_img, "2_before_rotation")
    
    # Perform the rotation on the normalized image
    rotated = cv2.warpAffine(cv_img, M, (width, height), 
                           flags=cv2.INTER_CUBIC, 
                           borderMode=cv2.BORDER_CONSTANT, 
                           borderValue=(255, 255, 255))  # White background

    # if Utils.is_debug():
    #     show_image(rotated, "3_after_rotation")
    
    if Utils.is_debug() and abs(transform_info['angle']) > 1:
        Utils.log_info(f"Applied rotation of {transform_info['angle']:.1f}°")
        pass
    
    # Convert back to PIL Image for cropping
    rotated_pil = Image.fromarray(cv2.cvtColor(rotated, cv2.COLOR_BGR2RGB))
    
    # Show before cropping
    # if Utils.is_debug():
    #     show_image(rotated, "4_before_crop")
    
    # Use crop rectangle from angle detection if available, otherwise use auto-crop
    if transform_info['crop_rect'] is not None:
        Utils.log_info(f"Using crop rectangle from angle detection: {transform_info['crop_rect']}")
        
        # Apply the crop rectangle
        final_img = rotated_pil.crop((
            transform_info['crop_rect']['x'], 
            transform_info['crop_rect']['y'], 
            transform_info['crop_rect']['x'] + transform_info['crop_rect']['width'], 
            transform_info['crop_rect']['y'] + transform_info['crop_rect']['height']
        ))
        
        # if Utils.is_debug():
        #     # Show the crop rectangle on the rotated image
        #     debug_crop = rotated.copy()
        #     cv2.rectangle(debug_crop, (transform_info['crop_rect']['x'], transform_info['crop_rect']['y']), 
        #                  (transform_info['crop_rect']['x'] + transform_info['crop_rect']['width'], 
        #                   transform_info['crop_rect']['y'] + transform_info['crop_rect']['height']), 
        #                  (0, 255, 255), 3)
        #     cv2.putText(debug_crop, f"CROP: {transform_info['crop_rect']['width']}x{transform_info['crop_rect']['height']}", 
        #                (transform_info['crop_rect']['x'], transform_info['crop_rect']['y']-10), 
        #                cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
        #     show_image(debug_crop, "4_crop_rectangle_applied")
        
    else:
        Utils.log_info("No crop rectangle available, using auto-crop")
        # Fallback to auto-crop (when using provided calibration_rect)
        final_img = auto_crop_document(rotated_pil, padding_percent)
    
    # Show final result
    # if Utils.is_debug():
    #     cv_final = cv2.cvtColor(np.array(final_img), cv2.COLOR_RGB2BGR)
    #     show_image(cv_final, "5_final_result")
    
    return final_img

def show_image(image, text="image"):
    cv2.imshow(text, image)
    while True:
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
    cv2.destroyAllWindows()

def get_calibration_rect_for_image(img_path, img=None):
    if img is None:
        img = cv2.imread(img_path, cv2.IMREAD_COLOR)
    elif isinstance(img, Image.Image):
        img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    
    # Get image dimensions
    height, width = img.shape[:2]
    center = (width/2, height/2)
    
    # Get the angle (we don't need the crop_rect here since this function 
    # is used when calibration_rect is provided to apply_calibration_to_image)
    angle, _ = detect_contour_angle(img)
    
    # Create a rectangle that covers most of the image
    rect_width = width * 0.95  # 95% of image width
    rect_height = height * 0.95  # 95% of image height
    
    # Return in the format expected by the rest of the code
    return (center, (rect_width, rect_height), angle)

def get_calibration_center_for_image(image_path, img=None):
    if img is None:
        img = cv2.imread(image_path, cv2.IMREAD_COLOR)
    elif isinstance(img, Image.Image):
        img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    
    height, width = img.shape[:2]
    return (width/2, height/2)  # Return center of image

def detect_shear_and_perspective(img):
    """
    Detect rotation angle using document corners detection.
    Uses the 4 most distant pixels to determine document orientation.
    Returns rotation angle and crop rectangle.
    """
    # Convert PIL Image to OpenCV format if needed
    if isinstance(img, Image.Image):
        cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    else:
        cv_img = img
    
    Utils.log_info("Detecting rotation using document corners (4 most distant pixels)")
    
    # Detect document corners and get angle
    corners = detect_document_corners(cv_img)
    
    if corners is not None:
        Utils.log_info("Document corners detected, using angle from rectangle")
        
        # Create a rectangle from the corners to get the angle
        corners_int = corners.astype(np.int32)
        rect = cv2.minAreaRect(corners_int)
        
        # Extract the angle from the rectangle
        angle = rect[2]
        width, height = rect[1]
        
        Utils.log_info(f"Raw angle from corners: {angle:.2f}°, dimensions: {width:.1f}x{height:.1f}")
        
        # Adjust angle based on rectangle orientation
        if width > height:
            # Landscape orientation
            if angle < -45:
                angle = 90 + angle
        else:
            # Portrait orientation  
            if angle < -45:
                angle = 90 + angle
            else:
                angle = angle
        
        # Limit the angle to reasonable rotation range
        if abs(angle) > 45:
            if angle > 0:
                angle = angle - 90
            else:
                angle = angle + 90
        
        Utils.log_info(f"Final adjusted angle: {angle:.2f}°")
        
        # Get crop rectangle from corners
        x_coords = corners[:, 0]
        y_coords = corners[:, 1]
        x_min, x_max = np.min(x_coords), np.max(x_coords)
        y_min, y_max = np.min(y_coords), np.max(y_coords)
        
        # Add some padding (2% of image dimensions)
        img_height, img_width = cv_img.shape[:2]
        padding_x = int(img_width * 0.02)
        padding_y = int(img_height * 0.02)
        
        # Apply padding but keep within image bounds
        crop_rect = {
            'x': max(0, x_min - padding_x),
            'y': max(0, y_min - padding_y),
            'width': min(img_width - max(0, x_min - padding_x), (x_max - x_min) + 2 * padding_x),
            'height': min(img_height - max(0, y_min - padding_y), (y_max - y_min) + 2 * padding_y)
        }
        
        return {
            'type': 'rotation',
            'angle': angle,
            'crop_rect': crop_rect,
            'method': 'document_corners'
        }
    
    # If corners detection failed, return no rotation
    Utils.log_info("No document corners found, returning no rotation")
    return {
        'type': 'rotation',
        'angle': 0,
        'crop_rect': None,
        'method': 'document_corners_failed'
    }




def detect_hough_line_skew(img):
    """
    Detect document skew using Hough line detection.
    This method works well for documents with clear text lines.
    Returns the skew angle in degrees.
    """
    # Convert PIL Image to OpenCV format if needed
    if isinstance(img, Image.Image):
        cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    else:
        cv_img = img
    
    Utils.log_info("Detecting skew using Hough line transform")
    
    # Convert to grayscale
    gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)
    
    # Apply Gaussian blur to reduce noise
    blurred = cv2.GaussianBlur(gray, (3, 3), 0)
    
    # Create binary image to enhance text
    _, binary = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    
    # Apply morphological operations to connect text elements
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (30, 1))  # Horizontal kernel to connect text
    morphed = cv2.morphologyEx(binary, cv2.MORPH_CLOSE, kernel)
    
    # Find edges
    edges = cv2.Canny(morphed, 50, 150, apertureSize=3)
    
    # Detect lines using Hough transform
    lines = cv2.HoughLines(edges, 1, np.pi/180, threshold=100)
    
    if lines is None:
        Utils.log_info("No lines detected with Hough transform")
        return 0
    
    Utils.log_info(f"Detected {len(lines)} lines with Hough transform")
    
    # Analyze line angles
    angles = []
    for line in lines:
        rho, theta = line[0]
        # Convert theta to angle in degrees
        # theta is in radians, 0 to pi
        angle = np.degrees(theta)
        
        # Focus on nearly horizontal lines (text lines)
        # Convert to range -90 to 90 degrees
        if angle > 90:
            angle = angle - 180
        elif angle < -90:
            angle = angle + 180
            
        # Only consider lines that are roughly horizontal (within 45 degrees)
        if abs(angle) <= 45:
            angles.append(angle)
    
    if not angles:
        Utils.log_info("No horizontal lines found for skew detection")
        return 0
    
    # Calculate the most common angle (mode)
    angles = np.array(angles)
    
    # Use histogram to find the most common angle
    hist, bin_edges = np.histogram(angles, bins=90, range=(-45, 45))
    max_bin_idx = np.argmax(hist)
    skew_angle = (bin_edges[max_bin_idx] + bin_edges[max_bin_idx + 1]) / 2
    
    # Alternatively, use median for robustness
    median_angle = np.median(angles)
    
    # Choose the angle with better support
    if hist[max_bin_idx] >= len(angles) * 0.3:  # At least 30% of lines agree
        final_angle = skew_angle
        Utils.log_info(f"Using histogram mode angle: {final_angle:.2f}° (support: {hist[max_bin_idx]}/{len(angles)})")
    else:
        final_angle = median_angle
        Utils.log_info(f"Using median angle: {final_angle:.2f}° (insufficient consensus for mode)")
    
    Utils.log_info(f"Detected skew angle using Hough lines: {final_angle:.2f}°")
    
    # if Utils.is_debug():
    #     # Visualize the detected lines
    #     debug_img = cv_img.copy()
    #     if lines is not None:
    #         for line in lines[:50]:  # Show first 50 lines
    #             rho, theta = line[0]
    #             a = np.cos(theta)
    #             b = np.sin(theta)
    #             x0 = a * rho
    #             y0 = b * rho
    #             x1 = int(x0 + 1000 * (-b))
    #             y1 = int(y0 + 1000 * (a))
    #             x2 = int(x0 - 1000 * (-b))
    #             y2 = int(y0 - 1000 * (a))
    #             cv2.line(debug_img, (x1, y1), (x2, y2), (0, 255, 0), 1)
    #     
    #     cv2.putText(debug_img, f"Skew: {final_angle:.1f}°", (10, 30),
    #                cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
    #     show_image(debug_img, "hough_lines_skew_detection")
    
    return final_angle

def detect_contour_angle_legacy(img):
    """
    Legacy method enhanced: Detect rotation angle and potential shear using convex hull.
    This focuses on text/content rather than document edges using convex hull.
    Can also detect perspective distortion if the hull forms a document-like quadrilateral.
    Now tries various parameters and uses the average of all valid results.
    Returns angle/perspective info and bounding rectangle.
    """
    # Convert PIL Image to OpenCV format if needed
    if isinstance(img, Image.Image):
        cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    else:
        cv_img = img
    
    if Utils.get_image_show_flag(FlagNames.LegacyAngleDetection):
        show_image(cv_img, "legacy_0_original")
    
    # Convert to grayscale
    gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)
    
    if Utils.get_image_show_flag(FlagNames.LegacyAngleDetection):
        show_image(gray, "legacy_1_grayscale")
    
    # Define parameter combinations to try
    parameter_sets = [
        # (blur_kernel, threshold, morph_kernel, description)
        ((3, 3), 50, (3, 3), "default_aggressive"),
        ((5, 5), 50, (3, 3), "more_blur_aggressive"), 
        ((3, 3), 70, (3, 3), "default_moderate"),
        ((5, 5), 70, (3, 3), "more_blur_moderate"),
        ((3, 3), 40, (5, 5), "very_aggressive_larger_morph"),
        ((7, 7), 60, (3, 3), "heavy_blur_balanced"),
        ((3, 3), 80, (2, 2), "conservative_small_morph"),
        ((5, 5), 45, (4, 4), "balanced_medium_morph"),
        ((3, 3), 55, (6, 6), "default_large_morph"),
        ((9, 9), 65, (3, 3), "maximum_blur_moderate")
    ]
    
    valid_results = []
    perspective_results = []
    
    Utils.log_info(f"Legacy method: Trying {len(parameter_sets)} parameter combinations")
    
    for i, (blur_kernel, threshold, morph_kernel, description) in enumerate(parameter_sets):
        Utils.log_info(f"Testing parameter set {i+1}/{len(parameter_sets)}: {description}")
        Utils.log_info(f"  Blur: {blur_kernel}, Threshold: {threshold}, Morph: {morph_kernel}")
        
        try:
            result = _detect_with_parameters(cv_img, gray, blur_kernel, threshold, morph_kernel, description)
            
            if result is not None:
                score = _score_detection_result(result, cv_img.shape)
                result['score'] = score
                Utils.log_info(f"  Result score: {score:.3f}")
                
                if result['type'] == 'perspective':
                    perspective_results.append(result)
                    Utils.log_info(f"  Added perspective result (distortion: {result['distortion_score']:.3f})")
                else:
                    valid_results.append(result)
                    Utils.log_info(f"  Added rotation result (angle: {result['angle']:.2f}°)")
            else:
                Utils.log_info(f"  No valid result for this parameter set")
                
        except Exception as e:
            Utils.log_info(f"  Parameter set failed: {e}")
            continue
    
    # Handle perspective results - if we have any high-quality perspective results, prefer them
    if perspective_results:
        # Filter perspective results by quality
        good_perspective = [r for r in perspective_results if r['score'] > 0.6 and r['distortion_score'] > 0.15]
        
        if good_perspective:
            Utils.log_info(f"Found {len(good_perspective)} high-quality perspective results")
            # Use the best perspective result
            best_perspective = max(good_perspective, key=lambda x: x['score'])
            Utils.log_info(f"Using best perspective result with score {best_perspective['score']:.3f}")
            return best_perspective
    
    # If no good perspective results, use rotation results
    if not valid_results:
        Utils.log_info("Legacy method: No valid rotation results found, returning default")
        return {'type': 'rotation', 'angle': 0, 'crop_rect': None}
    
    Utils.log_info(f"Legacy method: Averaging {len(valid_results)} valid rotation results")
    
    # Calculate weighted averages of angles and crop rectangles
    total_weight = sum(r['score'] for r in valid_results)
    
    if total_weight == 0:
        # If all scores are 0, use simple average
        Utils.log_info("All scores are 0, using simple average")
        weights = [1.0 / len(valid_results)] * len(valid_results)
    else:
        # Use score-based weighting
        weights = [r['score'] / total_weight for r in valid_results]
        Utils.log_info(f"Using weighted average (weights: {[f'{w:.3f}' for w in weights]})")
    
    # Calculate weighted average angle
    angles = [r['angle'] for r in valid_results]
    weighted_angle = sum(angle * weight for angle, weight in zip(angles, weights))
    
    # Calculate average crop rectangle
    crop_rects = [r['crop_rect'] for r in valid_results if r['crop_rect'] is not None]
    
    if crop_rects:
        # Calculate weighted average of crop rectangle bounds
        valid_crop_weights = []
        valid_crop_rects = []
        
        for i, result in enumerate(valid_results):
            if result['crop_rect'] is not None:
                valid_crop_weights.append(weights[i])
                valid_crop_rects.append(result['crop_rect'])
        
        # Normalize weights for crop rectangles
        crop_weight_sum = sum(valid_crop_weights)
        if crop_weight_sum > 0:
            normalized_crop_weights = [w / crop_weight_sum for w in valid_crop_weights]
        else:
            normalized_crop_weights = [1.0 / len(valid_crop_rects)] * len(valid_crop_rects)
        
        # Calculate weighted average bounds
        avg_x = sum(rect['x'] * weight for rect, weight in zip(valid_crop_rects, normalized_crop_weights))
        avg_y = sum(rect['y'] * weight for rect, weight in zip(valid_crop_rects, normalized_crop_weights))
        avg_x2 = sum((rect['x'] + rect['width']) * weight for rect, weight in zip(valid_crop_rects, normalized_crop_weights))
        avg_y2 = sum((rect['y'] + rect['height']) * weight for rect, weight in zip(valid_crop_rects, normalized_crop_weights))
        
        avg_crop_rect = {
            'x': int(avg_x),
            'y': int(avg_y),
            'width': int(avg_x2 - avg_x),
            'height': int(avg_y2 - avg_y)
        }
        
        Utils.log_info(f"Averaged crop rectangle: {avg_crop_rect}")
    else:
        avg_crop_rect = None
        Utils.log_info("No crop rectangles to average")
    
    # Calculate some statistics for logging
    angle_std = np.std(angles) if len(angles) > 1 else 0
    angle_range = max(angles) - min(angles) if len(angles) > 1 else 0
    
    Utils.log_info(f"Angle statistics: mean={weighted_angle:.2f}°, std={angle_std:.2f}°, range={angle_range:.2f}°")
    Utils.log_info(f"Individual angles: {[f'{a:.2f}°' for a in angles]}")
    scores_str = ", ".join([f"{r['score']:.3f}" for r in valid_results])
    Utils.log_info(f"Individual scores: [[{scores_str}]]")
    
    # Create final result
    final_result = {
        'type': 'rotation',
        'angle': weighted_angle,
        'crop_rect': avg_crop_rect,
        'method': 'averaged_legacy',
        'num_results_averaged': len(valid_results),
        'angle_std': angle_std,
        'angle_range': angle_range,
        'individual_angles': angles,
        'individual_scores': [r['score'] for r in valid_results]
    }
    
    if Utils.get_image_show_flag(FlagNames.LegacyAngleDetection):
        # Show the averaged result visualization
        debug_img = cv_img.copy()
        if avg_crop_rect:
            cv2.rectangle(debug_img, 
                         (avg_crop_rect['x'], avg_crop_rect['y']),
                         (avg_crop_rect['x'] + avg_crop_rect['width'], 
                          avg_crop_rect['y'] + avg_crop_rect['height']),
                         (255, 0, 0), 2)
        
        cv2.putText(debug_img, f"Averaged Result ({len(valid_results)} methods)", (10, 30),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
        cv2.putText(debug_img, f"Angle: {weighted_angle:.1f}° (±{angle_std:.1f}°)", (10, 60),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)
        cv2.putText(debug_img, f"Range: {angle_range:.1f}°", (10, 90),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 0, 0), 2)
        
        show_image(debug_img, "legacy_averaged_result")
    
    Utils.log_info(f"Legacy method: Final averaged angle: {weighted_angle:.2f}° (from {len(valid_results)} results)")
    
    return final_result

def _detect_with_parameters(cv_img, gray, blur_kernel, threshold, morph_kernel, description):
    """
    Helper function to run detection with specific parameters.
    """
    # Apply Gaussian blur to reduce noise
    blurred = cv2.GaussianBlur(gray, blur_kernel, 0)
    
    # Create threshold to get text/content
    _, thresh = cv2.threshold(blurred, threshold, 255, cv2.THRESH_BINARY_INV)
    
    # Apply morphological operations to connect nearby text
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, morph_kernel)
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
    
    if Utils.get_image_show_flag(FlagNames.LegacyAngleDetection):
        show_image(thresh, "legacy_threshold_result")
    
    # Find all black pixels (text/content pixels)
    black_pixels = np.column_stack(np.where(thresh > 0))
    
    if len(black_pixels) == 0:
        Utils.log_info(f"  No black pixels found with {description}")
        return None
    
    # Convert to (x, y) format for convex hull
    black_pixels_xy = np.array([(pt[1], pt[0]) for pt in black_pixels], dtype=np.int32)
    
    # Find the convex hull of all black pixels
    hull = cv2.convexHull(black_pixels_xy)
    
    if len(hull) < 3:
        Utils.log_info(f"  Insufficient hull points with {description}")
        return None
    
    Utils.log_info(f"  Found {len(black_pixels)} pixels, hull has {len(hull)} points")
    
    if Utils.get_image_show_flag(FlagNames.LegacyAngleDetection):
        hull_img = cv_img.copy()
        cv2.drawContours(hull_img, [hull], -1, (0, 255, 0), 2)
        show_image(hull_img, "legacy_hull_result")
    
    # Check if the hull can represent a document boundary (perspective correction)
    perspective_info = analyze_hull_for_perspective(hull, cv_img.shape)
    
    if perspective_info is not None:
        Utils.log_info(f"  Detected perspective distortion (score: {perspective_info['distortion_score']:.3f})")
        perspective_info['parameter_set'] = description
        perspective_info['pixel_count'] = len(black_pixels)
        perspective_info['hull_points'] = len(hull)
        return perspective_info
    
    # Fall back to rotation-only analysis
    # Get the minimum area rectangle that fits the convex hull
    rect = cv2.boundingRect(hull)
    
    # Extract the angle from the rectangle
    angle = rect[2]
    
    # Get the dimensions of the rectangle
    width, height = rect[1]
    
    # Adjust angle based on rectangle orientation
    if width > height:
        # Landscape orientation
        if angle < -45:
            angle = 90 + angle
    else:
        # Portrait orientation  
        if angle < -45:
            angle = 90 + angle
        else:
            angle = angle
    
    # Limit the angle to reasonable rotation range
    if abs(angle) > 45:
        if angle > 0:
            angle = angle - 90
        else:
            angle = angle + 90
    
    # Get the bounding rectangle coordinates
    box = cv2.boxPoints(rect)
    box = np.int32(box)
    
    if Utils.get_image_show_flag(FlagNames.LegacyAngleDetection):
        rect_img = cv_img.copy()
        cv2.drawContours(rect_img, [box], -1, (0, 0, 255), 2)
        cv2.putText(rect_img, f"Angle: {angle:.1f}°", (10, 30),
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 0, 255), 2)
        show_image(rect_img, "legacy_rect_result")
    
    # Get the axis-aligned bounding rectangle for cropping
    x_coords = box[:, 0]
    y_coords = box[:, 1]
    x_min, x_max = np.min(x_coords), np.max(x_coords)
    y_min, y_max = np.min(y_coords), np.max(y_coords)
    
    # Add some padding (2% of image dimensions)
    img_height, img_width = cv_img.shape[:2]
    padding_x = int(img_width * 0.02)
    padding_y = int(img_height * 0.02)
    
    # Apply padding but keep within image bounds
    crop_rect = {
        'x': max(0, x_min - padding_x),
        'y': max(0, y_min - padding_y),
        'width': min(img_width - max(0, x_min - padding_x), (x_max - x_min) + 2 * padding_x),
        'height': min(img_height - max(0, y_min - padding_y), (y_max - y_min) + 2 * padding_y)
    }
    
    Utils.log_info(f"  Detected angle: {angle:.1f}°, rect: {width:.1f}x{height:.1f}")
    
    return {
        'type': 'rotation', 
        'angle': angle, 
        'crop_rect': crop_rect,
        'parameter_set': description,
        'pixel_count': len(black_pixels),
        'hull_points': len(hull),
        'rect_dimensions': (width, height)
    }


def _score_detection_result(result, img_shape):
    """
    Score a detection result to determine quality.
    Higher score is better.
    """
    if result is None:
        return 0
    
    h, w = img_shape[:2]
    img_area = w * h
    score = 0
    
    # Base score for having a result
    score += 0.1
    
    # Score based on pixel count (more content pixels generally better)
    pixel_count = result.get('pixel_count', 0)
    pixel_ratio = pixel_count / img_area
    
    # Optimal pixel ratio is around 10-30% of image
    if 0.05 <= pixel_ratio <= 0.4:
        pixel_score = min(pixel_ratio / 0.2, (0.4 - pixel_ratio) / 0.2)
        score += 0.3 * pixel_score
    elif pixel_ratio < 0.05:
        score += 0.1 * (pixel_ratio / 0.05)  # Too few pixels
    # Too many pixels gets no bonus
    
    # Score based on result type and quality
    if result['type'] == 'perspective':
        # Perspective correction results
        distortion_score = result.get('distortion_score', 0)
        corner_score = result.get('corner_score', 0)
        
        # Prefer moderate distortion (not too little, not too much)
        if 0.15 <= distortion_score <= 0.5:
            score += 0.4 * min((distortion_score - 0.15) / 0.1, (0.5 - distortion_score) / 0.35)
        elif distortion_score > 0.5:
            score += 0.2  # Very distorted, but still valid
        
        # Corner quality bonus
        score += 0.2 * corner_score
        
    else:
        # Rotation results
        angle = abs(result.get('angle', 0))
        
        # Score based on angle reasonableness
        angle_reasonableness = get_angle_reasonableness_score(angle)
        score += 0.3 * angle_reasonableness
        
        # Crop rectangle quality
        crop_rect = result.get('crop_rect')
        if crop_rect:
            crop_area = crop_rect['width'] * crop_rect['height']
            crop_ratio = crop_area / img_area
            
            # Prefer crop rectangles that cover substantial portion of image
            if 0.3 <= crop_ratio <= 0.9:
                crop_score = min(crop_ratio / 0.6, (0.9 - crop_ratio) / 0.3)
                score += 0.2 * crop_score
        
        # Rectangle dimensions quality
        rect_dims = result.get('rect_dimensions')
        if rect_dims:
            width, height = rect_dims
            aspect_ratio = max(width, height) / (min(width, height) + 1e-6)
            
            # Reasonable aspect ratios (1:1 to 4:1)
            if 1 <= aspect_ratio <= 4:
                aspect_score = max(0, 1 - (aspect_ratio - 1) / 3)
                score += 0.1 * aspect_score
    
    # Hull quality bonus
    hull_points = result.get('hull_points', 0)
    if 4 <= hull_points <= 20:  # Good number of hull points
        hull_score = min(hull_points / 8, (20 - hull_points) / 16)
        score += 0.1 * hull_score
    
    return min(score, 1.0)  # Cap at 1.0


def analyze_hull_for_perspective(hull, img_shape):
    """
    Analyze the convex hull to see if it represents a perspective-distorted document.
    Returns perspective correction info if applicable, None otherwise.
    """
    # We need at least 4 points to form a quadrilateral
    if len(hull) < 4:
        return None
    
    h, w = img_shape[:2]
    hull_points = hull.reshape(-1, 2)
    
    # Try to find the 4 dominant corners of the hull that could represent document corners
    document_corners = find_document_corners_from_hull(hull_points, (w, h))
    
    if document_corners is None:
        return None
    
    # Validate if these corners form a reasonable document shape
    corner_score = validate_document_corners(document_corners, img_shape)
    
    if corner_score < 0.6:  # Increased threshold for hull-based detection
        Utils.log_info(f"Legacy method: Hull corners score too low: {corner_score:.3f}")
        return None
    
    # Calculate distortion score
    ideal_corners = np.array([
        [0, 0],
        [w, 0], 
        [w, h],
        [0, h]
    ], dtype=np.float32)
    
    distortion_score = calculate_perspective_distortion(document_corners, ideal_corners)
    
    # Only use perspective correction if distortion is significant - more conservative
    if distortion_score < 0.15:  # Increased threshold to match main detection
        Utils.log_info(f"Legacy method: Distortion not significant enough: {distortion_score:.3f}")
        return None
    
    
    # Create perspective transformation
    padding = min(w, h) * 0.02
    target_corners = np.array([
        [padding, padding],
        [w - padding, padding],
        [w - padding, h - padding],
        [padding, h - padding]
    ], dtype=np.float32)
    
    transform_matrix = cv2.getPerspectiveTransform(document_corners, target_corners)
    
    return {
        'type': 'perspective',
        'matrix': transform_matrix,
        'corners': document_corners,
        'target_corners': target_corners,
        'distortion_score': distortion_score,
        'corner_score': corner_score
    }


def find_document_corners_from_hull(hull_points, img_size):
    """
    Find 4 corners from convex hull points that best represent document boundaries.
    """
    w, h = img_size
    
    # If hull has exactly 4 points, use them
    if len(hull_points) == 4:
        return order_corners(hull_points.astype(np.float32))
    
    # If hull has more points, find the 4 most corner-like points
    if len(hull_points) > 4:
        return find_best_4_corners(hull_points, img_size)
    
    return None


def find_best_4_corners(hull_points, img_size):
    """
    From a set of hull points, find the 4 that best represent document corners.
    """
    w, h = img_size
    
    # Calculate angles at each hull point to find corners
    corner_scores = []
    n_points = len(hull_points)
    
    for i in range(n_points):
        prev_pt = hull_points[(i - 1) % n_points]
        curr_pt = hull_points[i]
        next_pt = hull_points[(i + 1) % n_points]
        
        # Calculate vectors
        v1 = prev_pt - curr_pt
        v2 = next_pt - curr_pt
        
        # Calculate angle
        cos_angle = np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2) + 1e-6)
        angle = np.arccos(np.clip(cos_angle, -1, 1))
        
        # Score based on how close to 90 degrees and position
        angle_score = abs(angle - np.pi/2)  # Lower is better (closer to 90°)
        
        # Bonus for being near image corners
        corner_distance = min(
            np.linalg.norm(curr_pt - [0, 0]),      # top-left
            np.linalg.norm(curr_pt - [w, 0]),      # top-right  
            np.linalg.norm(curr_pt - [w, h]),      # bottom-right
            np.linalg.norm(curr_pt - [0, h])       # bottom-left
        )
        position_score = corner_distance / max(w, h)  # Normalize
        
        # Combined score (lower is better)
        total_score = angle_score + position_score * 0.5
        corner_scores.append((total_score, i, curr_pt))
    
    # Sort by score and take best 4
    corner_scores.sort(key=lambda x: x[0])
    best_4_indices = [score[1] for score in corner_scores[:4]]
    best_4_points = np.array([hull_points[i] for i in sorted(best_4_indices)])
    
    # Verify we have a reasonable quadrilateral
    if len(best_4_points) == 4:
        return order_corners(best_4_points.astype(np.float32))
    
    return None

def detect_angle_with_fallback(img):
    """
    Detect rotation angle using multiple methods and choose the best result.
    Compares percentile-based method with legacy convex hull method.
    Both methods can now return either rotation or perspective correction.
    """
    # Convert PIL Image to OpenCV format if needed
    if isinstance(img, Image.Image):
        cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    else:
        cv_img = img
    
    Utils.log_info("Running angle detection with fallback comparison")
    
    # Method 1: New percentile-based method (rotation only for now)
    try:
        percentile_angle, percentile_crop = detect_contour_angle(cv_img)
        percentile_result = {'type': 'rotation', 'angle': percentile_angle, 'crop_rect': percentile_crop}
        percentile_success = True
        Utils.log_info(f"Percentile method result: {percentile_angle:.2f}° (rotation)")
    except Exception as e:
        Utils.log_info(f"Percentile method failed: {e}")
        percentile_result = {'type': 'rotation', 'angle': 0, 'crop_rect': None}
        percentile_success = False
    
    # Method 2: Enhanced legacy convex hull method (can return rotation or perspective)
    try:
        legacy_result = detect_contour_angle_legacy(cv_img)
        legacy_success = True
        if legacy_result['type'] == 'perspective':
            Utils.log_info(f"Legacy method result: perspective correction (distortion: {legacy_result['distortion_score']:.3f})")
        else:
            Utils.log_info(f"Legacy method result: {legacy_result['angle']:.2f}° (rotation)")
    except Exception as e:
        Utils.log_info(f"Legacy method failed: {e}")
        legacy_result = {'type': 'rotation', 'angle': 0, 'crop_rect': None}
        legacy_success = False
    
    # If only one method succeeded, use that one
    if percentile_success and not legacy_success:
        Utils.log_info("Only percentile method succeeded, using its result")
        return percentile_result['angle'], percentile_result['crop_rect'], 'percentile_only'
    elif legacy_success and not percentile_success:
        Utils.log_info("Only legacy method succeeded, using its result")
        if legacy_result['type'] == 'perspective':
            # Return the perspective info in a special format for the caller to handle
            return legacy_result, None, 'legacy_perspective_only'
        else:
            return legacy_result['angle'], legacy_result['crop_rect'], 'legacy_only'
    elif not percentile_success and not legacy_success:
        Utils.log_info("Both methods failed, returning 0 angle")
        return 0, None, 'both_failed'
    
    # Both methods succeeded, handle comparison
    if legacy_result['type'] == 'perspective':
        # If legacy detected perspective distortion, prefer it over simple rotation
        Utils.log_info("Legacy method detected perspective distortion, preferring perspective correction")
        return legacy_result, None, 'legacy_perspective_preferred'
    
    # Both are rotation methods, compare angles
    percentile_angle = percentile_result['angle']
    legacy_angle = legacy_result['angle']
    
    angle_difference = abs(percentile_angle - legacy_angle)
    Utils.log_info(f"Angle difference between methods: {angle_difference:.2f}°")
    
    # Define threshold for "significantly different"
    significant_difference_threshold = 2.0  # degrees
    
    if angle_difference <= significant_difference_threshold:
        # Results are similar, choose based on reliability criteria
        Utils.log_info(f"Methods agree (diff: {angle_difference:.2f}°), choosing based on reliability")
        
        # Prefer the method that detected a more reasonable angle (closer to common document skew)
        percentile_reasonableness = get_angle_reasonableness_score(percentile_angle)
        legacy_reasonableness = get_angle_reasonableness_score(legacy_angle)
        
        Utils.log_info(f"Percentile reasonableness: {percentile_reasonableness:.3f}, Legacy reasonableness: {legacy_reasonableness:.3f}")
        
        if percentile_reasonableness >= legacy_reasonableness:
            Utils.log_info("Using percentile method (similar results, better reasonableness)")
            return percentile_angle, percentile_result['crop_rect'], 'percentile_preferred'
        else:
            Utils.log_info("Using legacy method (similar results, better reasonableness)")
            return legacy_angle, legacy_result['crop_rect'], 'legacy_preferred'
    else:
        # Results are significantly different, choose the older method
        Utils.log_info(f"Methods disagree significantly (diff: {angle_difference:.2f}°), using older method")
        return legacy_angle, legacy_result['crop_rect'], 'legacy_chosen_on_disagreement'


def get_angle_reasonableness_score(angle):
    """
    Score how reasonable an angle is for document rotation.
    Higher score = more reasonable.
    """
    abs_angle = abs(angle)
    
    # Perfect angles get highest score
    if abs_angle < 0.5:
        return 1.0  # No rotation needed
    
    # Small angles are very reasonable
    if abs_angle <= 5:
        return 0.9
    
    # Medium angles are somewhat reasonable
    if abs_angle <= 15:
        return 0.7
    
    # Large angles are less reasonable but possible
    if abs_angle <= 30:
        return 0.5
    
    # Very large angles are suspicious
    if abs_angle <= 45:
        return 0.3
    
    # Extremely large angles are likely errors
    return 0.1


if __name__ == "__main__":
    images = convert_from_path("examples/target_examples/Marianna Dias.pdf")
    image = images[0]
    
    # Test the auto-crop functionality
    cropped_image = auto_crop_document(image)
    
    # Test the new text-based angle detection
    rotated_image = apply_calibration_to_image(image)
    
    # Display result
    cv_result = cv2.cvtColor(np.array(rotated_image), cv2.COLOR_RGB2BGR)
    #show_image(cv_result)
