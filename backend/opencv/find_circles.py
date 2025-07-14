import random
from PIL import Image
import cv2
import numpy as np
from utils import Utils, show_image
from websocket_types import BoxRectangleType
import json
import os
from datetime import datetime


def replace_all_not_used(text):
    text = "".join(list(filter(lambda x: (x in [str(i) for i in range(10)]) or (x in [chr(i) for i in range(65,91)]),list(text))))
    
    return text


def save_parameter_circle_counts(param_circle_counts, rectangle_type, rectangle_info=None):
    """
    Save parameter combination circle counts to a single aggregated JSON file.
    
    Args:
        param_circle_counts: Dictionary containing parameter combination -> circle count mapping
        rectangle_type: Type of rectangle being processed
        rectangle_info: Additional info about the rectangle
    """
    try:
        # Use a single filename for all rectangle types
        filename = "parameter_circle_counts_all_types.json"
        
        # Load existing data if file exists
        existing_data = {}
        if os.path.exists(filename):
            try:
                with open(filename, 'r') as f:
                    existing_data = json.load(f)
                Utils.log_info(f"📂 Loaded existing data from {filename}")
            except (json.JSONDecodeError, IOError) as e:
                Utils.log_error(f"Failed to load existing data from {filename}: {e}")
                existing_data = {}
        
        # Get rectangle type name
        rect_type_name = rectangle_type.value if hasattr(rectangle_type, 'value') else str(rectangle_type)
        
        # Initialize rectangle type array if it doesn't exist
        if rect_type_name not in existing_data:
            existing_data[rect_type_name] = []
        
        # Create new entry
        new_entry = {
            'timestamp': datetime.now().isoformat(),
            'parameter_combinations': param_circle_counts
        }
        
        if rectangle_info:
            new_entry['rectangle_info'] = {
                'name': rectangle_info.get('name', 'Unknown'),
                'index': rectangle_info.get('index', 1),
                'total': rectangle_info.get('total', 1),
                'page_info': rectangle_info.get('page_info', '')
            }
        
        # Append new data to the specific rectangle type
        existing_data[rect_type_name].append(new_entry)
        
        # Keep only last 50 entries per rectangle type to prevent file from growing too large
        if len(existing_data[rect_type_name]) > 50:
            existing_data[rect_type_name] = existing_data[rect_type_name][-50:]
            Utils.log_info(f"🗂️ Trimmed {rect_type_name} data to last 50 entries")
        
        # Save to file with pretty formatting
        with open(filename, 'w') as f:
            json.dump(existing_data, f, indent=2)
        
        # Log summary of what was saved
        total_combinations = len(param_circle_counts)
        max_circles = max(param_circle_counts.values()) if param_circle_counts else 0
        best_param = max(param_circle_counts.items(), key=lambda x: x[1]) if param_circle_counts else ("None", 0)
        entries_for_type = len(existing_data[rect_type_name])
        total_rect_types = len(existing_data)
        
        Utils.log_info(f"✅ Parameter circle counts saved to {filename}")
        Utils.log_info(f"📊 {rect_type_name} entry #{entries_for_type}: {total_combinations} parameter combinations tested")
        Utils.log_info(f"🏆 Best result: {best_param[0]} found {best_param[1]} circles")
        Utils.log_info(f"📈 File now contains data for {total_rect_types} rectangle types")
        
    except Exception as e:
        Utils.log_error(f"Failed to save parameter circle counts: {e}")


def distance_between_points(point1, point2):
    return ((point1[0] - point2[0])**2 + (point1[1] - point2[1])**2)/2


async def find_circles(img, rectangle, rectangle_type, on_progress=None):
    
    img = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)

    return await find_circles_cv2(img, rectangle, rectangle_type, img=img, on_progress=on_progress)

async def find_circles_fallback(image_path, rectangle, rectangle_type, template_circles, darkness_threshold=180/255, on_progress=None, img=None):

    if img is None:

        img = cv2.imread(image_path)

    



    image_new_width = 4000

    width_ratio = image_new_width / img.shape[1]

    img = cv2.resize(img,fx=width_ratio,fy=width_ratio,dsize=(0,0))


    
    

    old_x, old_y,width,height = rectangle.values()
    
    if old_x > 1 or old_y > 1 or width > 1 or height > 1 or old_x < 0 or old_y < 0 or width < 0 or height < 0:
        raise ValueError("The rectangle values must be between 0 and 1.")

    # transform to absolute
        
    x = int(old_x * img.shape[1])
    y = int(old_y * img.shape[0])
    width = int(width * img.shape[1])
    height = int(height * img.shape[0])

    if Utils.is_debug():

        # draw rectangle on image
        #cv2.rectangle(img, (x, y), (x + width, y + height), (0, 255, 0), 20)    
        pass

    # show image

    # crop image on rectangle

    crop_img = img[y:y+height, x:x+width]

    template_circles = list(map(lambda circ: [
        int((circ["center_x"] * img.shape[1]) - x),
        int((circ["center_y"] * img.shape[0]) -y),
        int(circ["radius"]*img.shape[1])],template_circles))
    
    if on_progress != None:
        await on_progress(f"Finding circles in image...")

    

    output_circles = []

    for i in template_circles:
        y_min = max(i[1] - i[2],0)
        x_min = max(i[0]-i[2],0)
        y_max = min(i[1] + i[2],crop_img.shape[0])
        x_max = min(i[0] + i[2],crop_img.shape[1])

        #Utils.log_info(f"y_min: {y_min} | x_min: {x_min} | y_max: {y_max} | x_max: {x_max}")

        circle_cropped = crop_img[y_min:y_max,x_min:x_max]

        # check if filled (black) circle

        filled = False

        if np.mean(circle_cropped) < darkness_threshold * 255:

            filled = True

            if Utils.is_debug():

                cv2.circle(crop_img, (i[0], i[1]), i[2], (255, 0, 0), 2)

        else:
            filled = False

            if Utils.is_debug():

                cv2.circle(crop_img, (i[0], i[1]), i[2], (0, 255, 0), 2)

        # draw the mean on crop_img in the center of the circle

        i[0] = i[0] + x

        i[1] = i[1] + y

        # now use the width_ratio

        i[0] = i[0] / width_ratio

        i[1] = i[1] / width_ratio

        i[2] = i[2] / width_ratio

        output_circles.append({
            "center_x": float(i[0]),
            "center_y": float(i[1]),
            "radius": float(i[2]),
            "filled": filled,
            "id": random.randbytes(10).hex()
        })

    if Utils.is_debug():
        #show_image(crop_img)
        pass

    return output_circles
        



def evaluate_circles_quality(circles, expected_count=None, min_radius=None, max_radius=None, img_shape=None):
    """
    Evaluate the quality of detected circles based on various metrics.
    Returns a score where higher is better.
    """
    if circles is None or len(circles[0]) == 0:
        return 0
    
    circles_array = circles[0]
    num_circles = len(circles_array)
    
    # Base score from number of circles
    if expected_count is not None:
        count_score = max(0, 1 - abs(num_circles - expected_count) / max(expected_count, 1))
    else:
        count_score = min(num_circles / 20, 1)  # Prefer more circles up to 20
    
    # Radius consistency score
    radii = [c[2] for c in circles_array]
    if len(radii) > 1:
        radius_std = np.std(radii)
        radius_mean = np.mean(radii)
        radius_consistency = max(0, 1 - (radius_std / radius_mean))
    else:
        radius_consistency = 1
    
    # Overlap penalty score - heavily penalize overlapping circles
    overlap_score = 1
    if len(circles_array) > 1:
        overlap_count = 0
        total_pairs = 0
        
        for i in range(len(circles_array)):
            for j in range(i + 1, len(circles_array)):
                total_pairs += 1
                circle1 = circles_array[i]
                circle2 = circles_array[j]
                
                # Calculate distance between centers
                distance = np.sqrt((circle1[0] - circle2[0])**2 + (circle1[1] - circle2[1])**2)
                
                # Check if circles overlap (distance < sum of radii with some tolerance)
                min_allowed_distance = (circle1[2] + circle2[2]) * 0.8  # 80% of sum of radii
                
                if distance < min_allowed_distance:
                    overlap_count += 1
        
        # Calculate overlap penalty (0 = all overlapping, 1 = no overlapping)
        if total_pairs > 0:
            overlap_score = max(0, 1 - (overlap_count / total_pairs))
    
    # Boundary penalty score - penalize circles outside image boundaries
    boundary_score = 1
    if img_shape is not None:
        img_height, img_width = img_shape[:2]
        outside_count = 0
        
        for circle in circles_array:
            center_x, center_y, radius = circle[0], circle[1], circle[2]
            
            # Check if circle extends outside image boundaries
            if (center_x - radius < 0 or  # Left boundary
                center_y - radius < 0 or  # Top boundary
                center_x + radius >= img_width or  # Right boundary
                center_y + radius >= img_height):  # Bottom boundary
                outside_count += 1
        
        # Calculate boundary penalty (0 = all outside, 1 = all inside)
        if num_circles > 0:
            boundary_score = max(0, 1 - (outside_count / num_circles))
    
    # Grid pattern score - reward proper rows and columns
    grid_score = 1
    if len(circles_array) >= 4:  # Need at least 4 circles to form a grid
        # Group circles into rows (similar Y coordinates)
        avg_radius = np.mean(radii)
        row_tolerance = avg_radius * 0.5  # Allow some tolerance for row alignment
        col_tolerance = avg_radius * 0.5  # Allow some tolerance for column alignment
        
        # Sort circles by Y coordinate to group into rows
        sorted_by_y = sorted(circles_array, key=lambda c: c[1])
        rows = []
        
        for circle in sorted_by_y:
            placed = False
            for row in rows:
                # Check if this circle belongs to an existing row
                if abs(circle[1] - row[0][1]) <= row_tolerance:
                    row.append(circle)
                    placed = True
                    break
            if not placed:
                rows.append([circle])
        
        # Group circles into columns (similar X coordinates)
        sorted_by_x = sorted(circles_array, key=lambda c: c[0])
        cols = []
        
        for circle in sorted_by_x:
            placed = False
            for col in cols:
                # Check if this circle belongs to an existing column
                if abs(circle[0] - col[0][0]) <= col_tolerance:
                    col.append(circle)
                    placed = True
                    break
            if not placed:
                cols.append([circle])
        
        # Calculate grid quality
        grid_quality = 0
        
        if len(rows) > 1 and len(cols) > 1:
            # Check row consistency (similar number of circles per row)
            row_sizes = [len(row) for row in rows]
            most_common_row_size = max(set(row_sizes), key=row_sizes.count)
            consistent_rows = sum(1 for size in row_sizes if abs(size - most_common_row_size) <= 1)
            row_consistency = consistent_rows / len(rows)
            
            # Check column consistency (similar number of circles per column)
            col_sizes = [len(col) for col in cols]
            most_common_col_size = max(set(col_sizes), key=col_sizes.count)
            consistent_cols = sum(1 for size in col_sizes if abs(size - most_common_col_size) <= 1)
            col_consistency = consistent_cols / len(cols)
            
            # Check row spacing consistency
            row_spacing_score = 1
            if len(rows) > 2:
                row_centers = [np.mean([c[1] for c in row]) for row in rows]
                row_spacings = [row_centers[i+1] - row_centers[i] for i in range(len(row_centers)-1)]
                if len(row_spacings) > 1:
                    spacing_std = np.std(row_spacings)
                    spacing_mean = np.mean(row_spacings)
                    row_spacing_score = max(0, 1 - (spacing_std / spacing_mean)) if spacing_mean > 0 else 0
            
            # Check column spacing consistency
            col_spacing_score = 1
            if len(cols) > 2:
                col_centers = [np.mean([c[0] for c in col]) for col in cols]
                col_spacings = [col_centers[i+1] - col_centers[i] for i in range(len(col_centers)-1)]
                if len(col_spacings) > 1:
                    spacing_std = np.std(col_spacings)
                    spacing_mean = np.mean(col_spacings)
                    col_spacing_score = max(0, 1 - (spacing_std / spacing_mean)) if spacing_mean > 0 else 0
            
            # Calculate overall grid quality
            grid_quality = (row_consistency + col_consistency + row_spacing_score + col_spacing_score) / 4
        
        grid_score = grid_quality
    
    # Spacing consistency score (for grid-like patterns)
    spacing_score = 1
    if len(circles_array) > 3:
        distances = []
        for i in range(len(circles_array)):
            for j in range(i + 1, len(circles_array)):
                dist = np.sqrt((circles_array[i][0] - circles_array[j][0])**2 + 
                             (circles_array[i][1] - circles_array[j][1])**2)
                distances.append(dist)
        
        if distances:
            distances = sorted(distances)
            # Look at the most common distance (assuming grid pattern)
            min_distances = [d for d in distances if d > np.mean(radii)][:num_circles]
            if len(min_distances) > 1:
                spacing_std = np.std(min_distances)
                spacing_mean = np.mean(min_distances)
                spacing_score = max(0, 1 - (spacing_std / spacing_mean))
    
    # Radius range score (prefer circles within expected range)
    radius_range_score = 1
    if min_radius is not None and max_radius is not None:
        in_range_count = sum(1 for r in radii if min_radius <= r <= max_radius)
        radius_range_score = in_range_count / num_circles if num_circles > 0 else 0
    
    # Combined score with weights - grid pattern has high weight
    total_score = (
        count_score * 0.15 +
        radius_consistency * 0.1 +
        overlap_score * 0.25 +  # High weight for overlap penalty
        boundary_score * 0.2 +  # High weight for boundary penalty
        grid_score * 0.25 +     # High weight for grid pattern reward
        spacing_score * 0.05 +
        radius_range_score * 0.0
    )
    
    return total_score

async def find_circles_hough_iterative(gray_img, dp_base, min_dist, min_radius, max_radius, 
                                 expected_count=None, circle_precision_percentage=1, on_progress=None, rectangle_info=None, crop_img=None):
    """
    Iteratively test different Hough circle parameters to find the best result.
    """
    best_circles = None
    best_score = -1
    best_params = None
    
    # Track circle counts for each parameter combination
    param_circle_counts = {}  # param_key -> circle_count
    
    # Track parameter combination results for consensus analysis
    param_combo_results = []  # List of (param_combo, score, circles) tuples
    
    # Parameter ranges to test
    dp_values = [1,1.2]
    param1_values = [0.4]
    param2_values = [2,5,9]
    threshold_values = [220,224,228,233,237,243]  # Different threshold values to test
    min_dist_values = [min_dist]
    
    total_combinations = len(dp_values) * len(param1_values) * len(param2_values) * len(threshold_values) * len(min_dist_values)
    Utils.log_info(f"Testing {total_combinations} parameter combinations...")
    
    # Format rectangle info for progress messages
    rect_info = ""
    if rectangle_info:
        page_info = rectangle_info.get('page_info', '')
        rect_name = rectangle_info.get('name', 'Unknown')
        rect_index = rectangle_info.get('index', 0)
        rect_total = rectangle_info.get('total', 1)
        rect_info = f"{page_info}[{rect_index}/{rect_total}] "
    
    test_count = 0
    for dp in dp_values:
        for param1 in param1_values:
            for param2 in param2_values:
                for threshold in threshold_values:
                    for test_min_dist in min_dist_values:
                        test_count += 1
                        progress_percent = (test_count / total_combinations) * 100
                        
                        # Update progress with current best score
                        best_score_text = f"Best: {best_score:.3f}" if best_score > -1 else "Best: None"
                        if on_progress is not None:
                            await on_progress(f"{rect_info}Testing {test_count}/{total_combinations} ({progress_percent:.1f}%)\n{best_score_text} | dp={dp}, param1={param1}, param2={param2}, threshold={threshold}")
                        
                        try:
                            # Apply threshold to the grayscale image
                            _, thresh_img = cv2.threshold(gray_img, threshold, 255, cv2.THRESH_BINARY)
                            
                            circles = cv2.HoughCircles(
                                thresh_img, 
                                cv2.HOUGH_GRADIENT, 
                                dp, 
                                test_min_dist,
                                param1=param1, 
                                param2=param2, 
                                minRadius=min_radius, 
                                maxRadius=max_radius
                            )
                            
                            score = evaluate_circles_quality(
                                circles, 
                                expected_count=expected_count,
                                min_radius=min_radius,
                                max_radius=max_radius,
                                img_shape=thresh_img.shape
                            )

                            param_combo = {
                                'dp': dp,
                                'param1': param1,
                                'param2': param2,
                                'threshold': threshold,
                                'min_dist': test_min_dist
                            }
                            
                            # Store parameter combination result
                            param_combo_results.append((param_combo, score, circles))

                            # Count circles found by this parameter combination
                            circle_count = len(circles[0]) if circles is not None and len(circles[0]) > 0 else 0
                            param_key = f"dp={dp}_p1={param1}_p2={param2}_th={threshold}"
                            param_circle_counts[param_key] = circle_count

                            #Utils.log_info(f"[{test_count}/{total_combinations}] ({progress_percent:.1f}%) Testing dp={dp}, param1={param1}, param2={param2}, threshold={threshold} → Score: {score:.3f}, Circles: {circle_count}")

                            """ if Utils.is_debug():
                                # show circles in image
                                gray_img_copy = thresh_img.copy()
                                # convert gray to rgb
                                gray_img_copy = cv2.cvtColor(gray_img_copy, cv2.COLOR_GRAY2RGB)
                                if circles is not None:
                                    for circle in circles[0]:
                                        # Convert coordinates to integers for OpenCV
                                        center_x = int(circle[0])
                                        center_y = int(circle[1])
                                        radius = int(circle[2])
                                        cv2.circle(gray_img_copy, (center_x, center_y), radius, (0, 0, 255), 2)
                                show_image(gray_img_copy, f"threshold_{threshold}_dp_{dp}")

                                Utils.log_info(f"Score: {score:.3f} with params: dp={dp}, param1={param1}, param2={param2}, threshold={threshold}, min_dist={test_min_dist}, num circles: {len(circles[0]) if circles is not None else 0}")
                             """
                            if score > best_score:
                                best_score = score
                                best_circles = circles
                                best_params = {
                                    'dp': dp,
                                    'param1': param1,
                                    'param2': param2,
                                    'threshold': threshold,
                                    'min_dist': test_min_dist
                                }
                                Utils.log_info(f"🎯 NEW BEST SCORE: {score:.3f} with {circle_count} circles! Params: dp={dp}, param1={param1}, param2={param2}, threshold={threshold}")
                                if on_progress is not None:
                                    await on_progress(f"{rect_info}🎯 NEW BEST!\nScore: {score:.3f}, Circles: {circle_count} | Progress: {progress_percent:.1f}%")
                        
                        except Exception as e:
                            Utils.log_error(f"Error with parameters dp={dp}, param1={param1}, param2={param2}, threshold={threshold}, min_dist={test_min_dist}: {e}")
                            continue

    Utils.log_info(f"✅ Parameter testing complete! Applying consensus recovery...")
    if on_progress is not None:
        await on_progress(f"{rect_info}Parameter testing complete!\nFinal score: {best_score:.3f} | Applying consensus recovery...")
    
    # Apply consensus-based circle recovery using top percentage of best-scoring combinations
    final_circle_count = 0
    if best_circles is not None and len(param_combo_results) > 0:
        Utils.log_info(f"🔄 Running consensus analysis on {len(param_combo_results)} parameter combinations...")
        enhanced_circles, circle_param_contributions = apply_consensus_recovery(best_circles[0], param_combo_results, top_percentage=0.4,min_frequency_ratio=0.4)
        
        # Filter circles by bounds before grid outlier removal
        Utils.log_info(f"🔍 Filtering circles by image bounds...")
        bounds_filtered_circles = filter_circles_by_bounds(enhanced_circles, gray_img.shape,max_outside_ratio=0.4)
        
        """ # Remove grid outliers after bounds filtering
        Utils.log_info(f"🧹 Removing grid outliers...")
        grid_filtered_circles = remove_grid_outliers(bounds_filtered_circles) """
        
        """ # Remove circles positioned between grid lines
        Utils.log_info(f"🎯 Removing between-grid circles...")
        grid_aligned_circles = remove_between_grid_circles(bounds_filtered_circles) """
        
        # Remove circles with too much white content (if crop_img is available)
        white_filtered_circles = bounds_filtered_circles
        if crop_img is not None:
            Utils.log_info(f"🔍 Removing circles with excessive white content...")
            white_filtered_circles = remove_white_content_circles(bounds_filtered_circles, crop_img)
        
        # Remove overlapping circles after all other filtering
        Utils.log_info(f"🔄 Removing overlapping circles...")
        filtered_circles = remove_overlapping_circles(white_filtered_circles)
        
        final_circle_count = len(filtered_circles)
        best_circles = np.array([filtered_circles], dtype=np.float32)
        
        white_filter_text = f"white content filtering reduced to {len(white_filtered_circles)} circles, " if crop_img is not None else ""
        Utils.log_info(f"✨ Analysis complete: Consensus recovery enhanced to {len(enhanced_circles)} circles, "
                      f"bounds filtering reduced to {len(bounds_filtered_circles)} circles, "
                      #f"grid outlier removal filtered to {len(grid_filtered_circles)} circles, "
                      #f"between-grid removal filtered to {len(grid_aligned_circles)} circles, "
                      f"{white_filter_text}"
                      f"overlap removal final result: {len(filtered_circles)} circles")
        progress_text = f"(bounds + outliers + between-grid + {'white-content + ' if crop_img is not None else ''}overlaps filtered)"
        if on_progress is not None:
            await on_progress(f"{rect_info}✨ Analysis complete!\nFinal result: {len(filtered_circles)} circles detected\n{progress_text}")
    else:
        if on_progress is not None:
            await on_progress(f"{rect_info}✨ Analysis complete!\nFinal result: {len(best_circles[0]) if best_circles is not None else 0} circles detected")

    # Create simple statistics structure
    param_stats = {
        'parameter_combinations': param_circle_counts,
        'final_circle_count': final_circle_count,
        'total_combinations_tested': len(param_circle_counts)
    }

    Utils.log_info(f"🏆 Final result - Best parameters: {best_params} with score: {best_score:.3f}")
    return best_circles, best_params, best_score, param_stats


def apply_consensus_recovery(best_circles, param_combo_results, 
                           location_tolerance=15, min_frequency_ratio=0.5, top_percentage=0.4):
    """
    Apply consensus-based recovery to add back frequently detected circles.
    Now focuses on the top percentage of best-scoring parameter combinations.
    
    Args:
        best_circles: Circles from the best parameter combination
        param_combo_results: List of (param_combo, score, circles) from all combinations
        location_tolerance: Pixel tolerance for considering circles at same location
        min_frequency_ratio: Minimum ratio of appearances in top combinations to be considered for recovery
        top_percentage: Percentage of top-scoring combinations to consider (0.4 = top 40%)
    
    Returns:
        enhanced_circles: List of enhanced circles
        circle_param_contributions: Dictionary mapping circle indices to parameter contribution info
    """
    # Sort parameter combinations by score (highest first) and take top percentage
    sorted_results = sorted(param_combo_results, key=lambda x: x[1], reverse=True)
    top_n = max(1, int(len(sorted_results) * top_percentage))
    top_results = sorted_results[:top_n]
    
    Utils.log_info(f"Analyzing consensus from top {len(top_results)} parameter combinations ({top_percentage*100:.0f}% of {len(param_combo_results)} total)")
    if Utils.is_debug():
        for i, (params, score, circles) in enumerate(top_results[:5]):  # Show top 5
            circle_count = len(circles[0]) if circles is not None and len(circles[0]) > 0 else 0
            Utils.log_info(f"  #{i+1}: Score {score:.3f}, {circle_count} circles, params: {params}")
    
    # Group all found circles from top results by location
    circle_locations = {}  # location_key -> list of (circle, param_combo, score)
    
    for param_combo, score, circles in top_results:
        if circles is not None and len(circles[0]) > 0:
            for circle in circles[0]:
                # Create a location key based on rounded coordinates
                location_key = (
                    round(circle[0] / location_tolerance) * location_tolerance,
                    round(circle[1] / location_tolerance) * location_tolerance
                )
                
                if location_key not in circle_locations:
                    circle_locations[location_key] = []
                circle_locations[location_key].append((circle, param_combo, score))
    
    # Count frequencies and find consensus circles
    consensus_circles = []
    circle_param_contributions = {}  # Will map circle index to parameter contribution info
    min_appearances = max(1, int(len(top_results) * min_frequency_ratio))
    
    Utils.log_info(f"Looking for circles that appear in at least {min_appearances} out of {len(top_results)} top combinations ({min_frequency_ratio*100:.0f}%)")
    
    for location_key, circles_at_location in circle_locations.items():
        frequency = len(circles_at_location)
        
        if frequency >= min_appearances:
            # Calculate average circle parameters for this location
            avg_x = np.mean([c[0][0] for c in circles_at_location])
            avg_y = np.mean([c[0][1] for c in circles_at_location])
            avg_radius = np.mean([c[0][2] for c in circles_at_location])
            avg_score = np.mean([c[2] for c in circles_at_location])
            
            consensus_circle = [avg_x, avg_y, avg_radius]
            consensus_circles.append((consensus_circle, frequency, avg_score, circles_at_location))
            
            Utils.log_info(f"Consensus circle at ({avg_x:.1f}, {avg_y:.1f}) appeared {frequency}/{len(top_results)} times in top combinations")
    
    # Check which consensus circles are missing from best result and build contribution tracking
    enhanced_circles = list(best_circles) if best_circles is not None else []
    
    # Track contributions for circles that were already in best result
    for i, existing_circle in enumerate(enhanced_circles):
        circle_param_contributions[i] = {
            'source': 'best_result',
            'contributing_params': [],
            'frequency': 1,
            'avg_score': 0.0
        }
        
        # Find which consensus location this circle belongs to
        for consensus_circle, frequency, avg_score, circles_at_location in consensus_circles:
            distance = np.sqrt((consensus_circle[0] - existing_circle[0])**2 + 
                             (consensus_circle[1] - existing_circle[1])**2)
            if distance <= location_tolerance:
                circle_param_contributions[i] = {
                    'source': 'best_result',
                    'contributing_params': [c[1] for c in circles_at_location],  # parameter combinations
                    'frequency': frequency,
                    'avg_score': avg_score
                }
                break
    
    # Add consensus circles that are missing from best result
    for consensus_circle, frequency, avg_score, circles_at_location in consensus_circles:
        # Check if this consensus circle is already represented in best_circles
        is_already_present = False
        
        for existing_circle in enhanced_circles:
            distance = np.sqrt((consensus_circle[0] - existing_circle[0])**2 + 
                             (consensus_circle[1] - existing_circle[1])**2)
            if distance <= location_tolerance:
                is_already_present = True
                break
        
        if not is_already_present:
            circle_index = len(enhanced_circles)
            enhanced_circles.append(consensus_circle)
            circle_param_contributions[circle_index] = {
                'source': 'consensus_recovery',
                'contributing_params': [c[1] for c in circles_at_location],  # parameter combinations
                'frequency': frequency,
                'avg_score': avg_score
            }
            Utils.log_info(f"Added consensus circle at ({consensus_circle[0]:.1f}, {consensus_circle[1]:.1f}) "
                          f"(appeared {frequency}/{len(top_results)} times in top combinations, avg_score: {avg_score:.3f})")
    
    return enhanced_circles, circle_param_contributions

def remove_grid_outliers(circles, tolerance_factor=0.5):
    """
    Remove circles that don't fit into a proper grid pattern.
    Filters out circles that are not aligned with the majority of rows and columns.
    
    Args:
        circles: List of circles [x, y, radius]
        tolerance_factor: Factor to determine alignment tolerance (0.5 = half of average radius)
    
    Returns:
        Filtered list of circles that form a proper grid
    """
    if len(circles) < 4:  # Need at least 4 circles to form a grid
        return circles
    
    # Convert to list of lists if needed (handle numpy arrays)
    circles_list = []
    for circle in circles:
        if hasattr(circle, '__len__') and len(circle) >= 3:
            circles_list.append([float(circle[0]), float(circle[1]), float(circle[2])])
        else:
            circles_list.append(circle)
    circles = circles_list
    
    # Calculate average radius for tolerance
    avg_radius = np.mean([c[2] for c in circles])
    row_tolerance = avg_radius * tolerance_factor
    col_tolerance = avg_radius * tolerance_factor
    
    Utils.log_info(f"Grid outlier removal: Starting with {len(circles)} circles, tolerance: {row_tolerance:.1f}px")
    
    # Group circles into rows (similar Y coordinates)
    sorted_by_y = sorted(circles, key=lambda c: c[1])
    rows = []
    
    for circle in sorted_by_y:
        placed = False
        for row in rows:
            # Check if this circle belongs to an existing row
            if abs(circle[1] - row[0][1]) <= row_tolerance:
                row.append(circle)
                placed = True
                break
        if not placed:
            rows.append([circle])
    
    # Group circles into columns (similar X coordinates)
    sorted_by_x = sorted(circles, key=lambda c: c[0])
    cols = []
    
    for circle in sorted_by_x:
        placed = False
        for col in cols:
            # Check if this circle belongs to an existing column
            if abs(circle[0] - col[0][0]) <= col_tolerance:
                col.append(circle)
                placed = True
                break
        if not placed:
            cols.append([circle])
    
    Utils.log_info(f"Grid analysis: Found {len(rows)} rows and {len(cols)} columns")
    
    # Keep ALL rows and columns - don't filter by size
    # Answer sheets can have different question types:
    # - True/False: 2 circles per row
    # - Multiple choice A,B,C,D: 4 circles per row  
    # - Multiple choice A,B,C,D,E: 5 circles per row
    # - Student ID: 10 circles per row
    valid_rows = rows  # Keep all rows
    valid_cols = cols  # Keep all columns
    
    # Log the variety of row and column sizes found
    row_sizes = [len(row) for row in rows]
    col_sizes = [len(col) for col in cols]
    
    if row_sizes:
        unique_row_sizes = sorted(set(row_sizes))
        Utils.log_info(f"Row sizes found: {unique_row_sizes} (keeping all)")
    
    if col_sizes:
        unique_col_sizes = sorted(set(col_sizes))
        Utils.log_info(f"Column sizes found: {unique_col_sizes} (keeping all)")
    
    # Find circles that belong to either valid rows OR valid columns
    valid_circles = []
    
    for circle in circles:
        in_valid_row = False
        in_valid_col = False
        
        # Check if circle is in a valid row
        for row in valid_rows:
            for r_circle in row:
                if abs(circle[0] - r_circle[0]) < 1 and abs(circle[1] - r_circle[1]) < 1:
                    in_valid_row = True
                    break
            if in_valid_row:
                break
        
        # Check if circle is in a valid column
        for col in valid_cols:
            for c_circle in col:
                if abs(circle[0] - c_circle[0]) < 1 and abs(circle[1] - c_circle[1]) < 1:
                    in_valid_col = True
                    break
            if in_valid_col:
                break
        
        # Keep circle if it's in either a valid row OR a valid column
        if in_valid_row or in_valid_col:
            valid_circles.append(circle)
        else:
            Utils.log_info(f"Removing outlier circle at ({circle[0]:.1f}, {circle[1]:.1f}) - "
                          f"not in any valid row or column")
    
    # Additional check: Remove isolated circles (circles with no nearby neighbors)
    # For answer sheets, we need to be more lenient since grids can be sparse
    final_circles = []
    min_neighbors = 1  # A circle should have at least 1 neighbor to be valid (reduced from 2)
    neighbor_distance = avg_radius * 4  # Search within 4 radii for neighbors (increased from 3)
    
    for i, circle in enumerate(valid_circles):
        neighbor_count = 0
        for j, other_circle in enumerate(valid_circles):
            if i != j:  # Use index comparison instead of array comparison
                distance = np.sqrt((circle[0] - other_circle[0])**2 + (circle[1] - other_circle[1])**2)
                if distance <= neighbor_distance:
                    neighbor_count += 1
        
        if neighbor_count >= min_neighbors:
            final_circles.append(circle)
        else:
            Utils.log_info(f"Removing truly isolated circle at ({circle[0]:.1f}, {circle[1]:.1f}) - "
                          f"only {neighbor_count} neighbors within {neighbor_distance:.1f}px (very likely a false detection)")
    
    Utils.log_info(f"Grid outlier removal complete: {len(circles)} → {len(final_circles)} circles "
                  f"({len(circles) - len(final_circles)} outliers removed)")
    
    return final_circles

def filter_circles_by_bounds(circles, img_shape, max_outside_ratio=0.9):
    """
    Filter out circles that are more than max_outside_ratio (50%) outside the image bounds.
    
    Args:
        circles: List of circles [x, y, radius]
        img_shape: Shape of the image (height, width)
        max_outside_ratio: Maximum ratio of circle area that can be outside bounds (0.5 = 50%)
    
    Returns:
        Filtered list of circles that are mostly within bounds
    """
    if not circles:
        return circles
    
    img_height, img_width = img_shape[:2]
    filtered_circles = []
    
    Utils.log_info(f"Bounds filtering: Image dimensions {img_width}x{img_height}, checking {len(circles)} circles")
    
    for circle in circles:
        x, y, radius = float(circle[0]), float(circle[1]), float(circle[2])

        
        
        # Calculate how much of the circle is outside each boundary
        left_outside = max(0, radius - x)  # How much extends past left edge
        right_outside = max(0, (x + radius) - img_width)  # How much extends past right edge
        top_outside = max(0, radius - y)  # How much extends past top edge
        bottom_outside = max(0, (y + radius) - img_height)  # How much extends past bottom edge
        
        # Calculate the area of the circle that's inside the image bounds
        # This is a simplified calculation - for exact calculation we'd need complex geometry
        
        # Check if circle center is inside bounds
        center_inside = (0 <= x < img_width) and (0 <= y < img_height)
        
        # Calculate approximate inside ratio based on how much extends outside
        total_circle_area = np.pi * radius * radius
        
        # Simple approximation: if circle extends outside by distance d, 
        # approximate the outside area as a fraction based on the distance
        outside_fraction = 0
        
        # If center is outside, most of circle is outside
        if not center_inside:
            outside_fraction = 0.8  # Assume 80% outside if center is outside
        else:
            # Calculate based on how much extends past each edge
            edge_penalties = []
            
            if left_outside > 0:
                edge_penalties.append(min(0.5, left_outside / radius))
            if right_outside > 0:
                edge_penalties.append(min(0.5, right_outside / radius))
            if top_outside > 0:
                edge_penalties.append(min(0.5, top_outside / radius))
            if bottom_outside > 0:
                edge_penalties.append(min(0.5, bottom_outside / radius))
            
            # Sum penalties but cap at 0.9 (90% outside)
            outside_fraction = min(0.9, sum(edge_penalties))
        Utils.log_info(f"Outside fraction: {outside_fraction} | circle: {circle} | img_shape: {img_shape}")
        
        inside_ratio = 1 - outside_fraction
        
        # Keep circle if more than (1 - max_outside_ratio) is inside bounds
        threshold = 1 - max_outside_ratio
        if inside_ratio >= threshold:
            filtered_circles.append(circle)
            if Utils.is_debug():
                Utils.log_info(f"KEEPING circle at ({x:.1f}, {y:.1f}) radius {radius:.1f} - "
                              f"{inside_ratio*100:.1f}% inside (threshold: {threshold*100:.1f}%)")
        else:
            Utils.log_info(f"REMOVING circle at ({x:.1f}, {y:.1f}) radius {radius:.1f} - "
                          f"only {inside_ratio*100:.1f}% inside bounds (threshold: {threshold*100:.1f}%) "
                          f"[left_out:{left_outside:.1f}, right_out:{right_outside:.1f}, top_out:{top_outside:.1f}, bottom_out:{bottom_outside:.1f}]")
    
    Utils.log_info(f"Bounds filtering: {len(circles)} → {len(filtered_circles)} circles "
                  f"({len(circles) - len(filtered_circles)} circles removed for being >{max_outside_ratio*100:.0f}% outside bounds)")
    
    return filtered_circles

def remove_overlapping_circles(circles, overlap_threshold=0.5):
    """
    Remove overlapping circles, keeping only one when multiple circles overlap.
    
    Args:
        circles: List of circles [x, y, radius]
        overlap_threshold: Minimum overlap ratio to consider circles as overlapping (0.5 = 50%)
    
    Returns:
        Filtered list of circles with overlaps removed
    """
    if len(circles) <= 1:
        return circles
    
    # Convert to list of lists if needed (handle numpy arrays)
    circles_list = []
    for circle in circles:
        if hasattr(circle, '__len__') and len(circle) >= 3:
            circles_list.append([float(circle[0]), float(circle[1]), float(circle[2])])
        else:
            circles_list.append(circle)
    circles = circles_list
    
    Utils.log_info(f"Overlap removal: Starting with {len(circles)} circles, threshold: {overlap_threshold*100:.0f}%")
    
    # Sort circles by some criteria to decide which one to keep when overlapping
    # We'll keep the circle with larger radius, or if radii are similar, the one with lower index
    circles_with_index = [(i, circle) for i, circle in enumerate(circles)]
    
    filtered_circles = []
    removed_indices = set()
    
    for i, (idx1, circle1) in enumerate(circles_with_index):
        if idx1 in removed_indices:
            continue
            
        x1, y1, r1 = circle1[0], circle1[1], circle1[2]
        keep_circle1 = True
        
        for j, (idx2, circle2) in enumerate(circles_with_index[i+1:], i+1):
            if idx2 in removed_indices:
                continue
                
            x2, y2, r2 = circle2[0], circle2[1], circle2[2]
            
            # Calculate distance between centers
            distance = np.sqrt((x1 - x2)**2 + (y1 - y2)**2)
            
            # Calculate overlap
            # Two circles overlap if distance < sum of radii
            # Overlap ratio = (r1 + r2 - distance) / min(2*r1, 2*r2)
            if distance < (r1 + r2):
                # Calculate overlap area ratio (simplified)
                overlap_distance = (r1 + r2) - distance
                smaller_diameter = 2 * min(r1, r2)
                overlap_ratio = overlap_distance / smaller_diameter
                
                if overlap_ratio >= overlap_threshold:
                    # Circles are overlapping significantly
                    # Decide which one to keep based on radius (keep larger) or index (keep first)
                    if r2 > r1 * 1.1:  # Keep circle2 if significantly larger
                        Utils.log_info(f"Removing circle at ({x1:.1f}, {y1:.1f}) radius {r1:.1f} - "
                                      f"overlaps {overlap_ratio*100:.1f}% with larger circle at ({x2:.1f}, {y2:.1f}) radius {r2:.1f}")
                        keep_circle1 = False
                        removed_indices.add(idx1)
                        break
                    else:  # Keep circle1 (current one)
                        Utils.log_info(f"Removing circle at ({x2:.1f}, {y2:.1f}) radius {r2:.1f} - "
                                      f"overlaps {overlap_ratio*100:.1f}% with circle at ({x1:.1f}, {y1:.1f}) radius {r1:.1f}")
                        removed_indices.add(idx2)
        
        if keep_circle1:
            filtered_circles.append(circle1)
    
    Utils.log_info(f"Overlap removal complete: {len(circles)} → {len(filtered_circles)} circles "
                  f"({len(circles) - len(filtered_circles)} overlapping circles removed)")
    
    return filtered_circles

def remove_between_grid_circles(circles, grid_tolerance_factor=0.8):
    """
    Remove circles that are positioned between grid lines rather than on the main grid structure.
    
    Args:
        circles: List of circles [x, y, radius]
        grid_tolerance_factor: Factor to determine grid line tolerance (0.3 = 30% of average radius)
    
    Returns:
        Filtered list of circles that are properly aligned with the main grid
    """
    if len(circles) < 4:  # Need at least 4 circles to determine a grid
        return circles
    
    # Convert to list of lists if needed (handle numpy arrays)
    circles_list = []
    for circle in circles:
        if hasattr(circle, '__len__') and len(circle) >= 3:
            circles_list.append([float(circle[0]), float(circle[1]), float(circle[2])])
        else:
            circles_list.append(circle)
    circles = circles_list
    
    # Calculate average radius for tolerance
    avg_radius = np.mean([c[2] for c in circles])
    grid_tolerance = avg_radius * grid_tolerance_factor
    
    Utils.log_info(f"Between-grid removal: Starting with {len(circles)} circles, grid tolerance: {grid_tolerance:.1f}px")
    
    # Extract all X and Y coordinates
    x_coords = [c[0] for c in circles]
    y_coords = [c[1] for c in circles]
    
    # Find main grid lines using clustering approach
    def find_main_grid_lines(coords, tolerance):
        """Find the main grid lines by clustering coordinates."""
        if not coords:
            return []
        
        sorted_coords = sorted(coords)
        grid_lines = []
        current_line = [sorted_coords[0]]
        
        for coord in sorted_coords[1:]:
            if coord - current_line[-1] <= tolerance:
                current_line.append(coord)
            else:
                # Finalize current line and start new one
                if len(current_line) >= 2:  # Only consider lines with at least 2 circles
                    grid_lines.append(np.mean(current_line))
                current_line = [coord]
        
        # Don't forget the last line
        if len(current_line) >= 2:
            grid_lines.append(np.mean(current_line))
        
        return grid_lines
    
    # Find main horizontal and vertical grid lines
    horizontal_grid_lines = find_main_grid_lines(y_coords, grid_tolerance)
    vertical_grid_lines = find_main_grid_lines(x_coords, grid_tolerance)
    
    Utils.log_info(f"Detected {len(horizontal_grid_lines)} horizontal and {len(vertical_grid_lines)} vertical grid lines")
    
    if Utils.is_debug():
        Utils.log_info(f"Horizontal grid lines (Y): {[f'{y:.1f}' for y in horizontal_grid_lines]}")
        Utils.log_info(f"Vertical grid lines (X): {[f'{x:.1f}' for x in vertical_grid_lines]}")
    
    # Filter circles that are properly aligned with grid lines
    aligned_circles = []
    
    for circle in circles:
        x, y = circle[0], circle[1]
        
        # Check if circle is aligned with any horizontal grid line
        aligned_horizontally = any(abs(y - grid_y) <= grid_tolerance for grid_y in horizontal_grid_lines)
        
        # Check if circle is aligned with any vertical grid line
        aligned_vertically = any(abs(x - grid_x) <= grid_tolerance for grid_x in vertical_grid_lines)
        
        # Keep circle only if it's aligned both horizontally and vertically
        if aligned_horizontally and aligned_vertically:
            aligned_circles.append(circle)
            if Utils.is_debug():
                Utils.log_info(f"KEEPING circle at ({x:.1f}, {y:.1f}) - aligned with grid")
        else:
            Utils.log_info(f"REMOVING between-grid circle at ({x:.1f}, {y:.1f}) - "
                          f"horizontal_aligned: {aligned_horizontally}, vertical_aligned: {aligned_vertically}")
    
    Utils.log_info(f"Between-grid removal complete: {len(circles)} → {len(aligned_circles)} circles "
                  f"({len(circles) - len(aligned_circles)} between-grid circles removed)")
    
    return aligned_circles

def remove_white_content_circles(circles, crop_img, max_white_percentage=0.99, white_threshold=200):
    """
    Remove circles that have too much white/light content inside them.
    This helps filter out false positive circles detected in areas that are mostly white.
    
    Args:
        circles: List of circles [x, y, radius]
        crop_img: The cropped image where circles were detected
        max_white_percentage: Maximum percentage of white content allowed (0.7 = 70%)
        white_threshold: Pixel intensity threshold to consider as "white" (200 for grayscale 0-255)
    
    Returns:
        Filtered list of circles with acceptable white content
    """
    if not circles or crop_img is None:
        return circles
    
    # Convert to list of lists if needed (handle numpy arrays)
    circles_list = []
    for circle in circles:
        if hasattr(circle, '__len__') and len(circle) >= 3:
            circles_list.append([float(circle[0]), float(circle[1]), float(circle[2])])
        else:
            circles_list.append(circle)
    circles = circles_list
    
    # Convert image to grayscale if it's not already
    if len(crop_img.shape) == 3:
        gray_img = cv2.cvtColor(crop_img, cv2.COLOR_BGR2GRAY)
    else:
        gray_img = crop_img.copy()
    
    img_height, img_width = gray_img.shape
    filtered_circles = []
    
    Utils.log_info(f"White content filtering: Starting with {len(circles)} circles, "
                  f"max_white_percentage: {max_white_percentage*100:.0f}%, white_threshold: {white_threshold}")
    
    for circle in circles:
        x, y, radius = int(circle[0]), int(circle[1]), int(circle[2])
        
        # Calculate the full bounding box for the circle (even if it extends outside image)
        full_y_min = y - radius
        full_x_min = x - radius
        full_y_max = y + radius
        full_x_max = x + radius
        
        # Calculate dimensions of the full circle region
        full_width = 2 * radius
        full_height = 2 * radius
        
        # Create a white background region for the circle
        circle_region = np.full((full_height, full_width), 255, dtype=np.uint8)  # White background
        
        # Calculate overlapping region between circle bbox and image
        overlap_x_min = max(full_x_min, 0)
        overlap_y_min = max(full_y_min, 0)
        overlap_x_max = min(full_x_max, img_width)
        overlap_y_max = min(full_y_max, img_height)
        
        # Check if there's any overlap with the image
        if overlap_x_min < overlap_x_max and overlap_y_min < overlap_y_max:
            # Extract the overlapping region from the original image
            img_overlap = gray_img[overlap_y_min:overlap_y_max, overlap_x_min:overlap_x_max]
            
            # Calculate where to place this overlap in the circle region
            dest_x_start = overlap_x_min - full_x_min
            dest_y_start = overlap_y_min - full_y_min
            dest_x_end = dest_x_start + (overlap_x_max - overlap_x_min)
            dest_y_end = dest_y_start + (overlap_y_max - overlap_y_min)
            
            # Place the image overlap into the white circle region
            circle_region[dest_y_start:dest_y_end, dest_x_start:dest_x_end] = img_overlap
        
        if circle_region.size == 0:
            Utils.log_info(f"REMOVING circle at ({circle[0]:.1f}, {circle[1]:.1f}) - empty region")
            continue
        
        # Create a circular mask for the region
        region_height, region_width = circle_region.shape
        center_x_local = radius  # Center is at radius offset in our full region
        center_y_local = radius
        
        # Create circular mask
        y_indices, x_indices = np.ogrid[:region_height, :region_width]
        mask = (x_indices - center_x_local)**2 + (y_indices - center_y_local)**2 <= radius**2
        
        # Extract only the pixels inside the circle
        circle_pixels = circle_region[mask]
        
        if len(circle_pixels) == 0:
            Utils.log_info(f"REMOVING circle at ({circle[0]:.1f}, {circle[1]:.1f}) - no pixels in mask")
            continue
        
        # Calculate the percentage of white pixels
        white_pixels = np.sum(circle_pixels >= white_threshold)
        total_pixels = len(circle_pixels)
        white_percentage = white_pixels / total_pixels
        
        # Keep circle if white percentage is below threshold
        if white_percentage <= max_white_percentage:
            filtered_circles.append(circle)
            if Utils.is_debug():
                Utils.log_info(f"KEEPING circle at ({circle[0]:.1f}, {circle[1]:.1f}) - "
                              f"{white_percentage*100:.1f}% white (threshold: {max_white_percentage*100:.0f}%)")
        else:
            Utils.log_info(f"REMOVING circle at ({circle[0]:.1f}, {circle[1]:.1f}) - "
                          f"{white_percentage*100:.1f}% white content (threshold: {max_white_percentage*100:.0f}%) "
                          f"[{white_pixels}/{total_pixels} white pixels]")
    
    Utils.log_info(f"White content filtering complete: {len(circles)} → {len(filtered_circles)} circles "
                  f"({len(circles) - len(filtered_circles)} circles removed for excessive white content)")
    
    return filtered_circles

async def find_circles_cv2(image_path, rectangle, rectangle_type, param2, dp, darkness_threshold=180/255, img=None, on_progress=None, circle_size=None, circle_precision_percentage=1, rectangle_info=None, use_parallel=False, max_workers=None):
    # Load the image
    Utils.log_info(f"Got circle size: {circle_size}")

    if img is None:
        img = cv2.imread(image_path)

    # make image 4000 width
    image_new_width = 4000
    width_ratio = image_new_width / img.shape[1]
    img = cv2.resize(img, fx=width_ratio, fy=width_ratio, dsize=(0, 0))

    old_x, old_y, width, height = rectangle.values()
    
    if old_x > 1 or old_y > 1 or width > 1 or height > 1 or old_x < 0 or old_y < 0 or width < 0 or height < 0:
        raise ValueError("The rectangle values must be between 0 and 1.")

    # transform to absolute
    x = int(old_x * img.shape[1])
    y = int(old_y * img.shape[0])
    width = int(width * img.shape[1])
    height = int(height * img.shape[0])

    if Utils.is_debug():
        # draw rectangle on image
        #cv2.rectangle(img, (x, y), (x + width, y + height), (0, 255, 0), 20)    
        pass

    # crop image on rectangle
    crop_img = img[y:y+height, x:x+width]

    # add some blur
    crop_img = cv2.GaussianBlur(crop_img, (17, 17), 1.5)

    # Convert cropped image to gray scale
    gray = cv2.cvtColor(crop_img, cv2.COLOR_BGR2GRAY)

    # Note: threshold is now handled inside the iterative function
    # _, gray = cv2.threshold(gray, 235, 255, cv2.THRESH_BINARY)

    #show_image(gray,"gray")

    min_dist = 120
    min_radius = 30
    max_radius = 33

    if circle_size is not None:
        # circle size is a percentage of width of the image
        circle_size = circle_size * img.shape[1]
        min_radius = int(circle_size * 1)
        max_radius = int(circle_size * 1.6)
        min_dist = int(circle_size * 2.5)
        Utils.log_info(f"Circle size: {circle_size} | min_radius: {min_radius} | max_radius: {max_radius} | min_dist: {min_dist}")

    # Prepare rectangle info for progress tracking
    if rectangle_info is None:
        rectangle_info = {
            'type': rectangle_type.value if hasattr(rectangle_type, 'value') else str(rectangle_type),
            'index': 1,
            'total': 1,
            'name': 'Unknown',
            'page_info': ''
        }
    else:
        # Use passed rectangle_info but ensure it has the type field
        rectangle_info = {
            'type': rectangle_type.value if hasattr(rectangle_type, 'value') else str(rectangle_type),
            'index': rectangle_info.get('index', 1),
            'total': rectangle_info.get('total', 1),
            'name': rectangle_info.get('name', 'Unknown'),
            'page_info': rectangle_info.get('page_info', '')
        }

    if on_progress is not None:
        processing_mode = "parallel" if use_parallel else "sequential"
        await on_progress(f"{rectangle_info['page_info']}[{rectangle_info['name']} {rectangle_info['index']}/{rectangle_info['total']}]\nStarting circle detection optimization ({processing_mode})...")

    # Estimate expected number of circles based on rectangle type
    expected_count = None
    if rectangle_type == BoxRectangleType.MATRICULA:
        # For matricula, estimate based on typical grid size
        area_ratio = (width * height) / (img.shape[0] * img.shape[1])
        expected_count = int(area_ratio * 200)  # Rough estimate
    
    # Choose between parallel and sequential processing
    if use_parallel:
        try:
            from find_circles_parallel import find_circles_hough_parallel
            circles, best_params, best_score, param_stats = await find_circles_hough_parallel(
                gray, dp, min_dist, min_radius, max_radius,
                expected_count=expected_count,
                circle_precision_percentage=circle_precision_percentage,
                on_progress=on_progress,
                rectangle_info=rectangle_info,
                crop_img=crop_img,
                max_workers=max_workers
            )
            Utils.log_info(f"✅ Parallel processing completed successfully")
        except ImportError as e:
            Utils.log_error(f"❌ Parallel processing not available, falling back to sequential: {e}")
            use_parallel = False
        except Exception as e:
            Utils.log_error(f"❌ Parallel processing failed, falling back to sequential: {e}")
            use_parallel = False
    
    if not use_parallel:
        # Fall back to original sequential processing
        circles, best_params, best_score, param_stats = await find_circles_hough_iterative(
            gray, dp, min_dist, min_radius, max_radius,
            expected_count=expected_count,
            circle_precision_percentage=circle_precision_percentage,
            on_progress=on_progress,
            rectangle_info=rectangle_info,
            crop_img=crop_img
        )
    
    Utils.log_info(f"Iterative Hough circles result - Score: {best_score:.3f}, Circles found: {len(circles[0]) if circles is not None else 0}")

    # Save parameter statistics to JSON file
    if param_stats:
        param_stats['best_params'] = best_params
        param_stats['best_score'] = best_score
        param_stats['image_dimensions'] = {
            'original_width': img.shape[1] // width_ratio,  # Original size before resize
            'original_height': img.shape[0] // width_ratio,
            'processed_width': img.shape[1],  # Size after resize
            'processed_height': img.shape[0],
            'crop_width': width,
            'crop_height': height
        }
        save_parameter_circle_counts(param_stats['parameter_combinations'], rectangle_type, rectangle_info)
        
        # Log summary
        total_combinations = param_stats.get('total_combinations_tested', 0)
        final_count = param_stats.get('final_circle_count', 0)
        best_combo = max(param_stats['parameter_combinations'].items(), key=lambda x: x[1]) if param_stats['parameter_combinations'] else ("None", 0)
        Utils.log_info(f"📊 Parameter testing summary: {total_combinations} combinations tested, {final_count} final circles")
        Utils.log_info(f"🏆 Best raw detection: {best_combo[0]} found {best_combo[1]} circles")

    if circles is None:
        return []

    circles = np.uint16(np.around(circles))

    if on_progress is not None:
        await on_progress(f"Circle detection complete!\nFound {len(circles[0])} circles in image.")

    output_circles = []

    for i in circles[0, :]:
        i = i.astype(int)
        y_min = max(i[1] - i[2], 0)
        x_min = max(i[0] - i[2], 0)
        y_max = min(i[1] + i[2], crop_img.shape[0])
        x_max = min(i[0] + i[2], crop_img.shape[1])

        try:
            # clamp to prevent accessing negative indices
            circle_cropped = crop_img[y_min:y_max, x_min:x_max]

            # check if filled (black) circle
            filled = False
            if np.mean(circle_cropped) < darkness_threshold * 255:
                filled = True
                if Utils.is_debug():
                    cv2.circle(crop_img, (i[0], i[1]), i[2], (255, 0, 0), 2)
            else:
                filled = False
                if Utils.is_debug():
                    cv2.circle(crop_img, (i[0], i[1]), i[2], (0, 255, 0), 2)

            if Utils.is_debug():
                cv2.putText(crop_img, str(int(np.mean(circle_cropped))), (i[0], i[1]), 
                          cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 0, 255), 2, cv2.LINE_AA)
                cv2.circle(crop_img, (i[0], i[1]), 2, (0, 0, 255), 3)

            # adjust circle to the original image
            i[0] = i[0] + x
            i[1] = i[1] + y

            # now use the width_ratio
            i[0] = i[0] / width_ratio
            i[1] = i[1] / width_ratio
            i[2] = i[2] / width_ratio

            output_circles.append({
                "center_x": float(i[0]),
                "center_y": float(i[1]),
                "radius": float(i[2]),
                "filled": filled,
                "id": random.randbytes(10).hex()
            })
        except Exception as e:
            Utils.log_error(i)

    # filter circles
    if circle_size is not None and rectangle_type == BoxRectangleType.MATRICULA:
        # find all "rows"
        Utils.log_info(f"Finding rows...")
        rows = []
        for circle in output_circles:
            found = False
            for row in rows:
                if distance_between_points((circle["center_x"], circle["center_y"]), 
                                        (row[0]["center_x"], row[0]["center_y"])) < circle_size * 1.5:
                    row.append(circle)
                    found = True
                    break
            if not found:
                rows.append([circle])

        # sort rows by y
        rows = sorted(rows, key=lambda x: x[0]["center_y"])

        # find the most common number of circles in a row
        most_common = max(set([len(row) for row in rows]), key=[len(row) for row in rows].count)

        # filter rows with less than most_common
        circles_to_remove = []
        for row in rows:
            if abs(len(row) - most_common) > 1:
                Utils.log_info(f"Removing row: {row}")
                circles_to_remove = circles_to_remove + [circle["id"] for circle in row]

        output_circles = [circle for circle in output_circles if circle["id"] not in circles_to_remove]

    #if Utils.is_debug():
    #    show_image(crop_img)

    return output_circles
