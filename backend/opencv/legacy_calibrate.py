import cv2
import numpy as np
from PIL import Image
from utils import Utils, FlagNames




def show_image(image, text="image"):
    """Displays an image in a window until 'q' is pressed."""
    Utils.show_image(image, text)


def order_corners(corners):
    """
    Order corners in a consistent way: top-left, top-right, bottom-right, bottom-left.
    """
    corners = corners[np.argsort(corners[:, 1])]
    top_two = corners[:2]
    bottom_two = corners[2:]
    top_two = top_two[np.argsort(top_two[:, 0])]
    bottom_two = bottom_two[np.argsort(bottom_two[:, 0])]
    return np.array([top_two[0], top_two[1], bottom_two[1], bottom_two[0]], dtype=np.float32)


def calculate_perspective_distortion(detected_corners, ideal_corners):
    """
    Calculate how much the detected corners deviate from an ideal rectangle.
    Returns a score where 0 = perfect rectangle, higher = more distortion.
    """
    h, w = ideal_corners[2, 1], ideal_corners[2, 0]
    norm_detected = detected_corners / np.array([w, h])
    norm_ideal = ideal_corners / np.array([w, h])
    distances = np.linalg.norm(norm_detected - norm_ideal, axis=1)
    avg_distance = np.mean(distances)
    return avg_distance




def validate_document_corners(corners, img_shape):
    """
    Validate detected corners to ensure they form a reasonable document rectangle.
    Returns a score between 0 and 1 (higher is better).
    """
    if len(corners) != 4:
        return 0
    h, w = img_shape[:2]
    score = 0
    if np.all(corners >= 0) and np.all(corners[:, 0] < w) and np.all(corners[:, 1] < h):
        score += 0.15
    else:
        return 0
    area = cv2.contourArea(corners)
    img_area = w * h
    area_ratio = area / img_area
    if 0.3 <= area_ratio <= 0.95:
        score += 0.25 * min(area_ratio / 0.7, (1 - area_ratio) / 0.05)
    elif area_ratio < 0.3:
        Utils.log_info(f"Corner area too small: {area_ratio:.3f} (need >= 0.3)")
        return 0
    ordered = order_corners(corners)
    sides = [np.linalg.norm(ordered[i] - ordered[(i + 1) % 4]) for i in range(4)]
    top_bottom_ratio = min(sides[0], sides[2]) / max(sides[0], sides[2])
    left_right_ratio = min(sides[1], sides[3]) / max(sides[1], sides[3])
    if top_bottom_ratio < 0.7 or left_right_ratio < 0.7:
        Utils.log_info(f"Sides not rectangular enough: TB={top_bottom_ratio:.3f}, LR={left_right_ratio:.3f}")
        return 0
    score += 0.25 * (top_bottom_ratio + left_right_ratio) / 2
    angles = []
    for i in range(4):
        p1 = ordered[(i - 1) % 4]
        p2 = ordered[i]
        p3 = ordered[(i + 1) % 4]
        v1 = p1 - p2
        v2 = p3 - p2
        cos_angle = np.dot(v1, v2) / (np.linalg.norm(v1) * np.linalg.norm(v2))
        angle = np.arccos(np.clip(cos_angle, -1, 1))
        angles.append(abs(np.degrees(angle) - 90))
    avg_angle_deviation = np.mean(angles)
    max_angle_deviation = np.max(angles)
    if avg_angle_deviation > 25 or max_angle_deviation > 40:
        Utils.log_info(f"Angles not rectangular: avg={avg_angle_deviation:.1f}°, max={max_angle_deviation:.1f}°")
        return 0
    angle_score = max(0, 1 - (avg_angle_deviation / 25))
    score += 0.2 * angle_score
    width_estimate = (sides[0] + sides[2]) / 2
    height_estimate = (sides[1] + sides[3]) / 2
    aspect_ratio = max(width_estimate, height_estimate) / min(width_estimate, height_estimate)
    if aspect_ratio <= 3.0:
        aspect_score = max(0, 1 - (aspect_ratio - 1) / 2)
        score += 0.15 * aspect_score
    else:
        Utils.log_info(f"Aspect ratio too extreme: {aspect_ratio:.2f}")
        return 0
    return score


def find_best_4_corners(hull_points):
    """
    From a set of hull points, find the 4 that best represent document corners.

    This implementation finds the four extreme points of the hull by identifying
    the points that are most top-left, top-right, bottom-right, and bottom-left.
    """
    if len(hull_points) < 4:
        return None

    # Ensure hull_points is a 2D array of shape (N, 2)
    if hull_points.ndim == 3:
        hull_points = hull_points.reshape(-1, 2)

    # For finding top-left and bottom-right corners
    s = hull_points.sum(axis=1)
    # For finding top-right and bottom-left corners
    # diff = y - x
    diff = hull_points[:, 1] - hull_points[:, 0]

    # Find the points in the hull that are the corners
    tl = hull_points[np.argmin(s)]
    br = hull_points[np.argmax(s)]
    tr = hull_points[np.argmin(diff)]
    bl = hull_points[np.argmax(diff)]
    
    corners = np.array([tl, tr, br, bl], dtype=np.float32)

    # Order the corners consistently (TL, TR, BR, BL) using the more
    # robust sorting-based order_corners function defined earlier in the file.
    return order_corners(corners)


def find_document_corners_from_hull(hull_points, img_size):
    """Find 4 corners from convex hull points that best represent document boundaries."""
    if len(hull_points) == 4:
        return order_corners(hull_points.astype(np.float32))
    if len(hull_points) > 4:
        return find_best_4_corners(hull_points)
    return None


def analyze_hull_for_perspective(hull, cv_img):
    """
    Analyze the convex hull to see if it represents a perspective-distorted document.
    """
    # We need at least 4 points to form a quadrilateral
    if len(hull) < 4:
        return None
    
    h, w = cv_img.shape[:2]
    img_shape = cv_img.shape
    hull_points = hull.reshape(-1, 2)
    
    # Show hull points visualization
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        debug_img = cv_img.copy()
        cv2.drawContours(debug_img, [hull], -1, (255, 0, 0), 1) # Hull in blue
        for i, point in enumerate(hull_points):
            cv2.circle(debug_img, tuple(point.astype(int)), 3, (255, 255, 0), -1)  # Cyan dots
            cv2.putText(debug_img, str(i), tuple(point.astype(int) + 5), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.4, (255, 255, 0), 1)
        show_image(debug_img, f"Hull Points ({len(hull_points)} points)")
    
    # Try to find the 4 dominant corners of the hull that could represent document corners
    document_corners = find_document_corners_from_hull(hull_points, (w, h))
    
    if document_corners is None:
        Utils.log_info("Legacy method: No document corners found")
        return None

    # Show found corners
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        debug_img = cv_img.copy()
        cv2.drawContours(debug_img, [hull], -1, (255, 0, 0), 1) # Hull in blue
        cv2.drawContours(debug_img, [document_corners.astype(int)], -1, (0, 255, 0), 2) # Corners in green
        corner_labels = ['TL', 'TR', 'BR', 'BL']
        for i, corner in enumerate(document_corners):
            cv2.circle(debug_img, tuple(corner.astype(int)), 8, (0, 0, 255), -1)  # Red circles
            cv2.putText(debug_img, corner_labels[i], tuple(corner.astype(int) + 10), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 0, 255), 2)
        show_image(debug_img, "Found Document Corners")

    # Calculate corner score for return value (no longer used for filtering)
    corner_score = validate_document_corners(document_corners, img_shape)
    
    # Calculate distortion score
    ideal_corners = np.array([
        [0, 0],
        [w, 0], 
        [w, h],
        [0, h]
    ], dtype=np.float32)
    
    distortion_score = calculate_perspective_distortion(document_corners, ideal_corners)
    
    # Show distortion comparison
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        debug_img = cv_img.copy()
        # Draw detected corners in red
        cv2.drawContours(debug_img, [document_corners.astype(int)], -1, (0, 0, 255), 2)
        # Draw ideal corners in blue
        cv2.drawContours(debug_img, [ideal_corners.astype(int)], -1, (255, 0, 0), 2)
        cv2.putText(debug_img, f"Distortion Score: {distortion_score:.3f}", (10, 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
        cv2.putText(debug_img, f"Corner Score: {corner_score:.3f}", (10, 60), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
        show_image(debug_img, "Distortion Analysis (Red=Detected, Blue=Ideal)")
    
    # Create perspective transformation
    padding = min(w, h) * 0.2
    target_corners = np.array([
        [padding, padding],
        [w - padding, padding],
        [w - padding, h - padding],
        [padding, h - padding]
    ], dtype=np.float32)
    
    transform_matrix = cv2.getPerspectiveTransform(document_corners, target_corners)

    # Show transformation preview
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        debug_img = cv_img.copy()
        # Draw source corners in red
        cv2.drawContours(debug_img, [document_corners.astype(int)], -1, (0, 0, 255), 2)
        # Draw target corners in green
        cv2.drawContours(debug_img, [target_corners.astype(int)], -1, (0, 255, 0), 2)
        
        # Draw lines showing the transformation
        for i in range(4):
            cv2.line(debug_img, tuple(document_corners[i].astype(int)), 
                    tuple(target_corners[i].astype(int)), (255, 255, 0), 1)
        
        cv2.putText(debug_img, "Perspective Transform Preview", (10, 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (255, 255, 255), 2)
        cv2.putText(debug_img, "Red=Source, Green=Target, Cyan=Transform", (10, 60), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
        show_image(debug_img, "Perspective Transform Setup")
    
    return {
        'type': 'perspective',
        'matrix': transform_matrix,
        'corners': document_corners,
        'document_corners': document_corners,
        'distortion_score': distortion_score,
        'corner_score': corner_score
    }


def _score_detection_result(result, img_shape):
    """Scores a detection result to determine quality. Higher score is better."""
    if result is None:
        return 0
    h, w = img_shape[:2]
    img_area = w * h
    score = 0.1
    pixel_count = result.get('pixel_count', 0)
    pixel_ratio = pixel_count / img_area
    if 0.05 <= pixel_ratio <= 0.4:
        pixel_score = min(pixel_ratio / 0.2, (0.4 - pixel_ratio) / 0.2)
        score += 0.3 * pixel_score
    elif pixel_ratio < 0.05:
        score += 0.1 * (pixel_ratio / 0.05)
    if result['type'] == 'perspective':
        distortion_score = result.get('distortion_score', 0)
        corner_score = result.get('corner_score', 0)
        if 0.15 <= distortion_score <= 0.5:
            score += 0.4 * min((distortion_score - 0.15) / 0.1, (0.5 - distortion_score) / 0.35)
        elif distortion_score > 0.5:
            score += 0.2
        score += 0.2 * corner_score
    else:
        angle = abs(result.get('angle', 0))
        crop_rect = result.get('crop_rect')
        if crop_rect:
            crop_ratio = (crop_rect['width'] * crop_rect['height']) / img_area
            if 0.3 <= crop_ratio <= 0.9:
                score += 0.2 * min(crop_ratio / 0.6, (0.9 - crop_ratio) / 0.3)
        rect_dims = result.get('rect_dimensions')
        if rect_dims:
            width, height = rect_dims
            aspect_ratio = max(width, height) / (min(width, height) + 1e-6)
            if 1 <= aspect_ratio <= 4:
                score += 0.1 * max(0, 1 - (aspect_ratio - 1) / 3)
    hull_points = result.get('hull_points', 0)
    if 4 <= hull_points <= 20:
        score += 0.1 * min(hull_points / 8, (20 - hull_points) / 16)
    return min(score, 1.0)


def _detect_with_parameters(cv_img, gray, blur_kernel, threshold, morph_kernel, description):
    """Helper function to run detection with specific parameters - always returns perspective info."""
    blurred = cv2.GaussianBlur(gray, blur_kernel, 0)
    _, thresh = cv2.threshold(blurred, threshold, 255, cv2.THRESH_BINARY_INV)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, morph_kernel)
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_CLOSE, kernel)
    
    if Utils.get_image_show_flag(FlagNames.LegacyAngleDetection):
        show_image(thresh, f"legacy_thresh_{description}")
    
    black_pixels = np.column_stack(np.where(thresh > 0))
    if len(black_pixels) < 100:
        return None
    
    black_pixels_xy = np.array([(pt[1], pt[0]) for pt in black_pixels], dtype=np.int32)
    hull = cv2.convexHull(black_pixels_xy)
    if len(hull) < 3:
        return None
    
    # Show hull visualization
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        debug_img = cv_img.copy()
        cv2.drawContours(debug_img, [hull], -1, (0, 255, 0), 2)  # Green for hull
        cv2.putText(debug_img, f"Hull Points: {len(hull)} ({description})", (10, 30), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
        show_image(debug_img, f"Hull Detection - {description}")
    
    # Always try to get perspective info
    perspective_info = analyze_hull_for_perspective(hull, cv_img)
    if perspective_info is not None:
        perspective_info.update({'parameter_set': description, 'pixel_count': len(black_pixels), 'hull_points': len(hull)})
        return perspective_info
    
    # If no perspective info, return None instead of rotation info
    return None


def detect_contour_angle_legacy(img):
    """
    Legacy method: Detect perspective correction using convex hull.
    """
    cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR) if isinstance(img, Image.Image) else img
    gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)
    
    # Show input image
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        show_image(cv_img, "Input Image for Legacy Detection")
        show_image(gray, "Grayscale Input")
    
    parameter_sets = [
        ((3, 3), 50, (3, 3), "default_moderate"), 
        ((5, 5), 70, (3, 3), "more_blur_moderate"),
        ((3, 3), 90, (2, 2), "conservative_small_morph"), 
        ((5, 5), 45, (4, 4), "balanced_medium_morph"),
    ]
    
    # Try each parameter set until we get a perspective result
    for i, params in enumerate(parameter_sets):
        try:
            Utils.log_info(f"Trying parameter set {i+1}/{len(parameter_sets)}: {params[3]}")
            result = _detect_with_parameters(cv_img, gray, *params)
            if result and result['type'] == 'perspective':
                Utils.log_info(f"Success with parameter set: {params[3]}")
                return result
            else:
                Utils.log_info(f"No perspective found with parameter set: {params[3]}")
        except Exception as e:
            Utils.log_info(f"Parameter set {params[3]} failed: {e}")
    
    # If no perspective correction found, return a default rotation result
    Utils.log_info("No perspective correction found, returning default rotation")
    return {'type': 'rotation', 'angle': 0, 'crop_rect': None}

def normalize_image_brightness(img):
    """
    Normalize image by stretching the darkest pixels to pure black.
    Only adjusts the dark end of the range.
    
    Args:
        img: Input image (PIL Image or OpenCV format)
        
    Returns:
        Normalized image in same format as input
    """
    # Convert to OpenCV format if needed
    cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR) if isinstance(img, Image.Image) else img.copy()
    was_pil = isinstance(img, Image.Image)
    
    # Store original for debug visualization
    original_for_show = cv_img.copy() if Utils.get_image_show_flag(FlagNames.LegacyShowNormalization) else None
    
    # Find darkest 1% value in each channel
    dark_points = []
    for channel in cv2.split(cv_img):
        dark_val = np.percentile(channel, 1)  # Use 1st percentile to avoid outliers
        dark_points.append(dark_val)
    
    # Stretch each channel so darkest point becomes 0
    for i, channel in enumerate(cv2.split(cv_img)):
        if dark_points[i] > 0:  # Only adjust if darkest isn't already 0
            scale = 255.0 / (255.0 - dark_points[i])
            channel = np.clip((channel - dark_points[i]) * scale, 0, 255).astype(np.uint8)
            cv_img[:,:,i] = channel
    
    # Debug visualization
    if Utils.get_image_show_flag(FlagNames.LegacyShowNormalization):
        comparison = np.hstack((original_for_show, cv_img))
        show_image(comparison, "Normalization Before & After (black point)")

    # Convert back to original format
    return Image.fromarray(cv2.cvtColor(cv_img, cv2.COLOR_BGR2RGB)) if was_pil else cv_img


def auto_crop_document(img, padding_percent=0.005):
    """Automatically crop a scanned document to remove empty white spaces."""
    cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR) if isinstance(img, Image.Image) else img
    original_pil = img if isinstance(img, Image.Image) else Image.fromarray(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
    height, width = cv_img.shape[:2]
    
    # Show input to auto crop
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        show_image(cv_img, "Auto Crop Input")
    
    gray = cv2.cvtColor(cv_img, cv2.COLOR_BGR2GRAY)
    blurred = cv2.GaussianBlur(gray, (5, 5), 0)
    thresh = cv2.adaptiveThreshold(blurred, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 11, 10)
    
    # Show thresholding result for auto crop
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        show_image(thresh, "Auto Crop Threshold")
    
    contours, _ = cv2.findContours(thresh, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if not contours:
        return original_pil
        
    largest_contour = max(contours, key=cv2.contourArea)
    x, y, w, h = cv2.boundingRect(largest_contour)
    coords = np.column_stack(np.where(thresh > 0))
    
    if len(coords) > 0:
        y_min, x_min = coords.min(axis=0)
        y_max, x_max = coords.max(axis=0)
        if (x_max - x_min) * (y_max - y_min) > w * h * 1.2:
            x, y, w, h = x_min, y_min, x_max - x_min, y_max - y_min
    
    # Show detected crop area
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        debug_img = cv_img.copy()
        cv2.rectangle(debug_img, (x, y), (x + w, y + h), (0, 255, 0), 3)
        cv2.putText(debug_img, f"Crop Area: {w}x{h}", (x, y-10), 
                   cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
        show_image(debug_img, "Auto Crop Detection")
    
    padding_x = int(width * padding_percent)
    padding_y = int(height * padding_percent)
    x = max(0, x - padding_x)
    y = max(0, y - padding_y)
    w = min(width - x, w + 2 * padding_x)
    h = min(height - y, h + 2 * padding_y)
    
    if w < width * 0.5 or h < height * 0.5:
        return original_pil
        
    cropped_result = original_pil.crop((x, y, x + w, y + h))
    
    # Show final cropped result
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        cv_cropped = cv2.cvtColor(np.array(cropped_result), cv2.COLOR_RGB2BGR)
        show_image(cv_cropped, "Auto Crop Result")
    
    return cropped_result


def apply_perspective_correction(img, transform_info):
    """Apply perspective correction using the detected transformation."""
    cv_img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR) if isinstance(img, Image.Image) else img
    was_pil = isinstance(img, Image.Image)
    height, width = cv_img.shape[:2]
    
    # Show input before perspective correction
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        show_image(cv_img, "Before Perspective Correction")
    
    corrected = cv2.warpPerspective(cv_img, transform_info['matrix'], (width, height),
                                  flags=cv2.INTER_CUBIC, borderMode=cv2.BORDER_CONSTANT,
                                  borderValue=(255, 255, 255))

    # Show result after perspective warp
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        show_image(corrected, "After Perspective Warp")

    padding = min(width, height) * 0.02
    cropped = corrected[int(padding):int(height-padding), int(padding):int(width-padding)]
    
    # Show result after padding crop
    if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
        show_image(cropped, "After Perspective Crop")
    
    return Image.fromarray(cv2.cvtColor(cropped, cv2.COLOR_BGR2RGB)) if was_pil else cropped


def apply_calibration_to_image(img: Image, padding_percent=0.005):
    """
    Applies image calibration using only the legacy convex-hull based method.
    This function will normalize, correct for rotation/perspective, and crop the image.
    """
    Utils.log_info("Starting calibration process")
    
    # Show original input
    if Utils.get_image_show_flag(FlagNames.LegacyShowFinalImage):
        cv_original = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
        show_image(cv_original, "Original Input Image")
    
    # 1. Normalize brightness and contrast
    Utils.log_info("Step 1: Normalizing image brightness")
    normalized_img = normalize_image_brightness(img)
    cv_img = cv2.cvtColor(np.array(normalized_img), cv2.COLOR_RGB2BGR)

    # Show normalized result
    if Utils.get_image_show_flag(FlagNames.LegacyShowFinalImage):
        show_image(cv_img, "After Normalization")

    # 2. Detect transformation using the legacy method
    Utils.log_info("Step 2: Detecting document transformation")
    transform_info = detect_contour_angle_legacy(normalized_img)

    # 3. Apply the detected transformation
    if transform_info['type'] == 'perspective':
        """ Utils.log_info(f"Step 3a: Applying perspective correction (distortion: {transform_info['distortion_score']:.3f})")
        corrected_img = apply_perspective_correction(cv_img, transform_info)
        
        # Show perspective corrected result
        if Utils.get_image_show_flag(FlagNames.LegacyShowFinalImage):
            cv_perspective = cv2.cvtColor(np.array(corrected_img), cv2.COLOR_RGB2BGR)
            show_image(cv_perspective, "After Perspective Correction")
        
        Utils.log_info("Step 4a: Cropping using transform corners with padding") """
        
        # Get the target corners from the transform info and crop directly
        target_corners = transform_info['document_corners']
        height, width = cv_img.shape[:2]
        
        # Calculate crop bounds from target corners with additional padding
        x_min = max(0, int(np.min(target_corners[:, 0])) - int(width * padding_percent))
        y_min = max(0, int(np.min(target_corners[:, 1])) - int(height * padding_percent))
        x_max = min(width, int(np.max(target_corners[:, 0])) + int(width * padding_percent))
        y_max = min(height, int(np.max(target_corners[:, 1])) + int(height * padding_percent))
        
        # Show crop bounds on perspective corrected image
        if Utils.get_image_show_flag(FlagNames.LegacyShowParamResults):
            debug_img = cv_img.copy()
            # Draw target corners
            cv2.drawContours(debug_img, [target_corners.astype(int)], -1, (0, 255, 0), 2)
            # Draw crop rectangle
            cv2.rectangle(debug_img, (x_min, y_min), (x_max, y_max), (255, 0, 0), 3)
            cv2.putText(debug_img, f"Crop: {x_max-x_min}x{y_max-y_min}", (x_min, y_min-10), 
                       cv2.FONT_HERSHEY_SIMPLEX, 0.7, (255, 0, 0), 2)
            cv2.putText(debug_img, "Green=Target Corners, Blue=Crop Area", (10, 30),
                       cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
            show_image(debug_img, "Perspective Crop Bounds")
        
        # Crop the image using PIL

        # convert to PIL
        final_img = Image.fromarray(cv2.cvtColor(cv_img, cv2.COLOR_BGR2RGB))

        # crop the image
        final_img = final_img.crop((x_min, y_min, x_max, y_max))

        # convert to cv2
        final_img = cv2.cvtColor(np.array(final_img), cv2.COLOR_RGB2BGR)
        
    else: # 'rotation'
        angle = transform_info.get('angle', 0)
        Utils.log_info(f"Step 3b: Applying rotation of {angle:.1f}°")
        height, width = cv_img.shape[:2]
        center = (width // 2, height // 2)
        M = cv2.getRotationMatrix2D(center, angle, 1.0)
        rotated = cv2.warpAffine(cv_img, M, (width, height),
                               flags=cv2.INTER_CUBIC,
                               borderMode=cv2.BORDER_CONSTANT,
                               borderValue=(255, 255, 255))
        
        # Show rotation result
        if Utils.get_image_show_flag(FlagNames.LegacyShowFinalImage):
            show_image(rotated, f"After Rotation ({angle:.1f}°)")
        
        rotated_pil = Image.fromarray(cv2.cvtColor(rotated, cv2.COLOR_BGR2RGB))
        
        # 4. Crop the image
        crop_rect = transform_info.get('crop_rect')
        if crop_rect:
            Utils.log_info("Step 4b: Applying detected crop rectangle")
            # Show crop rectangle on rotated image
            if Utils.get_image_show_flag(FlagNames.LegacyShowFinalImage):
                debug_img = rotated.copy()
                cv2.rectangle(debug_img, 
                             (crop_rect['x'], crop_rect['y']),
                             (crop_rect['x'] + crop_rect['width'], 
                              crop_rect['y'] + crop_rect['height']),
                             (0, 255, 0), 3)
                cv2.putText(debug_img, "Detected Crop Area", (10, 30),
                           cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
                show_image(debug_img, "Rotation with Crop Rectangle")
            
            final_img = rotated_pil.crop((
                crop_rect['x'], crop_rect['y'],
                crop_rect['x'] + crop_rect['width'],
                crop_rect['y'] + crop_rect['height']
            ))
        else:
            Utils.log_info("Step 4b: Auto-cropping rotated image")
            final_img = auto_crop_document(rotated_pil, padding_percent)

    # Show processing summary
    if Utils.get_image_show_flag(FlagNames.LegacyShowFinalImage):
        # Create before/after comparison
        original_cv = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
        final_cv = cv2.cvtColor(np.array(final_img), cv2.COLOR_RGB2BGR)
        
        # Resize images to same height for comparison
        h_orig, w_orig = original_cv.shape[:2]
        h_final, w_final = final_cv.shape[:2]
        target_height = min(h_orig, h_final, 800)  # Limit height for display
        
        # Resize original
        ratio_orig = target_height / h_orig
        new_w_orig = int(w_orig * ratio_orig)
        resized_orig = cv2.resize(original_cv, (new_w_orig, target_height))
        
        # Resize final
        ratio_final = target_height / h_final
        new_w_final = int(w_final * ratio_final)
        resized_final = cv2.resize(final_cv, (new_w_final, target_height))
        
        # Create comparison
        comparison = np.hstack((resized_orig, resized_final))
        cv2.putText(comparison, "BEFORE", (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
        cv2.putText(comparison, "AFTER", (new_w_orig + 10, 30), cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
        show_image(comparison, "Final Comparison: Before vs After")
        
        show_image(final_cv, "Final Calibrated Image")

    Utils.log_info("Calibration process completed successfully")
    return final_img


if __name__ == '__main__':
    from pdf2image import convert_from_path
    import os

    # --- Configuration ---
    # Initialize utilities and set debug flags as needed
    Utils.load_from_env()  # Load settings from .env file
    Utils.set_image_show_flag(FlagNames.LegacyAngleDetection, False)
    Utils.set_image_show_flag(FlagNames.LegacyShowParamResults, True)
    Utils.set_image_show_flag(FlagNames.LegacyShowAverageResult, True)
    Utils.set_image_show_flag(FlagNames.LegacyShowNormalization, True)
    Utils.set_image_show_flag(FlagNames.LegacyShowFinalImage, True)

    # --- Example Usage ---
    try:
        # Create an 'examples' folder if it doesn't exist
        if not os.path.exists("examples"):
            print("Creating 'examples' directory. Please add a PDF to test.")
        
        # Find the first PDF in the examples directory
        pdf_path = None
        for file in os.listdir("examples"):
            if file.lower().endswith(".pdf"):
                pdf_path = os.path.join("examples", file)
                break
        
        if not pdf_path:
            print("No PDF found in 'examples' directory. Please add one to run the test.")
        else:
            print(f"Processing PDF: {pdf_path}")
            # Convert first page of PDF to an image
            images = convert_from_path(pdf_path)
            if images:
                image = images[0]

                # Apply the legacy calibration
                calibrated_image = apply_calibration_to_image(image)
                
                # Create an 'output' folder if it doesn't exist
                if not os.path.exists("output"):
                    os.makedirs("output")

                # Save the result
                output_path = "output/legacy_calibrated_output.png"
                calibrated_image.save(output_path)
                print(f"Successfully processed image. Result saved to: {output_path}")

                # Optionally display the final image
                # calibrated_image.show()
            else:
                print("Could not extract any images from the PDF.")

    except Exception as e:
        print(f"An error occurred: {e}")
        print("Please ensure you have a PDF in the 'examples' folder and that poppler is installed.") 