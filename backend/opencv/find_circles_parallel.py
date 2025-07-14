import multiprocessing as mp
import numpy as np
import cv2
from concurrent.futures import ProcessPoolExecutor, as_completed
from utils import Utils
from find_circles import evaluate_circles_quality

def test_parameter_combination(args):
    """
    Test a single parameter combination for circle detection.
    This function will run in a separate process.
    
    Args:
        args: Tuple of (gray_img_bytes, img_shape, params_dict)
    
    Returns:
        Dict with results: {
            'param_combo': dict,
            'score': float,
            'circles': ndarray or None,
            'circle_count': int
        }
    """
    try:
        # Unpack arguments
        gray_img_bytes, img_shape, params = args
        
        # Reconstruct grayscale image from bytes
        gray_img = np.frombuffer(gray_img_bytes, dtype=np.uint8).reshape(img_shape)
        
        # Extract parameters
        dp = params['dp']
        param1 = params['param1']
        param2 = params['param2']
        threshold = params['threshold']
        min_dist = params['min_dist']
        min_radius = params['min_radius']
        max_radius = params['max_radius']
        expected_count = params['expected_count']
        
        # Apply threshold to the grayscale image
        _, thresh_img = cv2.threshold(gray_img, threshold, 255, cv2.THRESH_BINARY)
        
        # Detect circles
        circles = cv2.HoughCircles(
            thresh_img, 
            cv2.HOUGH_GRADIENT, 
            dp, 
            min_dist,
            param1=param1, 
            param2=param2, 
            minRadius=min_radius, 
            maxRadius=max_radius
        )
        
        # Evaluate quality
        score = evaluate_circles_quality(
            circles, 
            expected_count=expected_count,
            min_radius=min_radius,
            max_radius=max_radius,
            img_shape=thresh_img.shape
        )
        
        # Count circles
        circle_count = len(circles[0]) if circles is not None and len(circles[0]) > 0 else 0
        
        # Create parameter key for tracking
        param_key = f"dp={dp}_p1={param1}_p2={param2}_th={threshold}"
        
        return {
            'param_combo': params,
            'param_key': param_key,
            'score': score,
            'circles': circles,
            'circle_count': circle_count,
            'success': True
        }
        
    except Exception as e:
        return {
            'param_combo': params,
            'param_key': f"dp={params.get('dp', '?')}_p1={params.get('param1', '?')}_p2={params.get('param2', '?')}_th={params.get('threshold', '?')}",
            'score': 0,
            'circles': None,
            'circle_count': 0,
            'success': False,
            'error': str(e)
        }

async def find_circles_hough_parallel(gray_img, dp_base, min_dist, min_radius, max_radius, 
                                    expected_count=None, circle_precision_percentage=1, 
                                    on_progress=None, rectangle_info=None, crop_img=None, 
                                    max_workers=None):
    """
    Parallelized version of find_circles_hough_iterative using multiprocessing.
    
    Args:
        max_workers: Number of parallel processes (defaults to CPU count)
    """
    
    # Determine number of workers
    if max_workers is None:
        max_workers = min(mp.cpu_count(), 8)  # Cap at 8 to avoid overwhelming system
    
    Utils.log_info(f"🚀 Starting parallel circle detection with {max_workers} workers")
    
    best_circles = None
    best_score = -1
    best_params = None
    
    # Track results
    param_circle_counts = {}
    param_combo_results = []
    
    # Parameter ranges to test
    dp_values = [1, 1.2]
    param1_values = [0.4]
    param2_values = [2, 5, 9]
    threshold_values = [220, 224, 228, 233, 237, 243]
    min_dist_values = [min_dist]
    
    # Generate all parameter combinations
    param_combinations = []
    for dp in dp_values:
        for param1 in param1_values:
            for param2 in param2_values:
                for threshold in threshold_values:
                    for test_min_dist in min_dist_values:
                        param_combinations.append({
                            'dp': dp,
                            'param1': param1,
                            'param2': param2,
                            'threshold': threshold,
                            'min_dist': test_min_dist,
                            'min_radius': min_radius,
                            'max_radius': max_radius,
                            'expected_count': expected_count
                        })
    
    total_combinations = len(param_combinations)
    Utils.log_info(f"Testing {total_combinations} parameter combinations in parallel...")
    
    # Format rectangle info for progress messages
    rect_info = ""
    if rectangle_info:
        page_info = rectangle_info.get('page_info', '')
        rect_name = rectangle_info.get('name', 'Unknown')
        rect_index = rectangle_info.get('index', 0)
        rect_total = rectangle_info.get('total', 1)
        rect_info = f"{page_info}[{rect_index}/{rect_total}] "
    
    # Convert grayscale image to bytes for multiprocessing
    gray_img_bytes = gray_img.tobytes()
    img_shape = gray_img.shape
    
    # Prepare arguments for worker processes
    worker_args = []
    for params in param_combinations:
        worker_args.append((gray_img_bytes, img_shape, params))
    
    # Progress tracking
    completed_count = 0
    
    if on_progress is not None:
        await on_progress(f"{rect_info}Starting parallel processing...\n{max_workers} workers, {total_combinations} combinations")
    
    # Execute parameter combinations in parallel
    with ProcessPoolExecutor(max_workers=max_workers) as executor:
        # Submit all tasks
        future_to_params = {
            executor.submit(test_parameter_combination, args): args[2] 
            for args in worker_args
        }
        
        # Process results as they complete
        for future in as_completed(future_to_params):
            completed_count += 1
            progress_percent = (completed_count / total_combinations) * 100
            
            try:
                result = future.result()
                
                if result['success']:
                    # Store results
                    param_combo_results.append((
                        result['param_combo'], 
                        result['score'], 
                        result['circles']
                    ))
                    param_circle_counts[result['param_key']] = result['circle_count']
                    
                    # Check if this is the best result so far
                    if result['score'] > best_score:
                        best_score = result['score']
                        best_circles = result['circles']
                        best_params = result['param_combo']
                        
                        Utils.log_info(f"🎯 NEW BEST SCORE: {result['score']:.3f} with {result['circle_count']} circles! "
                                     f"Params: dp={best_params['dp']}, param1={best_params['param1']}, "
                                     f"param2={best_params['param2']}, threshold={best_params['threshold']}")
                        
                        if on_progress is not None:
                            await on_progress(f"{rect_info}🎯 NEW BEST!\n"
                                            f"Score: {result['score']:.3f}, Circles: {result['circle_count']}\n"
                                            f"Progress: {progress_percent:.1f}% ({completed_count}/{total_combinations})")
                else:
                    Utils.log_error(f"Parameter combination failed: {result.get('error', 'Unknown error')}")
                
                # Update progress periodically
                if completed_count % 5 == 0 or completed_count == total_combinations:
                    best_score_text = f"Best: {best_score:.3f}" if best_score > -1 else "Best: None"
                    if on_progress is not None:
                        await on_progress(f"{rect_info}Processing... {completed_count}/{total_combinations} ({progress_percent:.1f}%)\n{best_score_text}")
                        
            except Exception as e:
                Utils.log_error(f"Error processing future result: {e}")
                continue
    
    Utils.log_info(f"✅ Parallel parameter testing complete! Processing {total_combinations} combinations with {max_workers} workers")
    if on_progress is not None:
        await on_progress(f"{rect_info}Parallel testing complete!\nFinal score: {best_score:.3f} | Applying consensus recovery...")
    
    # Apply the same post-processing as the original function
    from find_circles import apply_consensus_recovery, filter_circles_by_bounds, remove_white_content_circles, remove_overlapping_circles
    
    final_circle_count = 0
    if best_circles is not None and len(param_combo_results) > 0:
        Utils.log_info(f"🔄 Running consensus analysis on {len(param_combo_results)} parameter combinations...")
        enhanced_circles, circle_param_contributions = apply_consensus_recovery(
            best_circles[0], param_combo_results, top_percentage=0.4, min_frequency_ratio=0.4
        )
        
        # Filter circles by bounds
        Utils.log_info(f"🔍 Filtering circles by image bounds...")
        bounds_filtered_circles = filter_circles_by_bounds(enhanced_circles, gray_img.shape, max_outside_ratio=0.4)
        
        # Remove circles with too much white content (if crop_img is available)
        white_filtered_circles = bounds_filtered_circles
        if crop_img is not None:
            Utils.log_info(f"🔍 Removing circles with excessive white content...")
            white_filtered_circles = remove_white_content_circles(bounds_filtered_circles, crop_img)
        
        # Remove overlapping circles
        Utils.log_info(f"🔄 Removing overlapping circles...")
        filtered_circles = remove_overlapping_circles(white_filtered_circles)
        
        final_circle_count = len(filtered_circles)
        best_circles = np.array([filtered_circles], dtype=np.float32)
        
        white_filter_text = f"white content filtering reduced to {len(white_filtered_circles)} circles, " if crop_img is not None else ""
        Utils.log_info(f"✨ Parallel analysis complete: Consensus recovery enhanced to {len(enhanced_circles)} circles, "
                      f"bounds filtering reduced to {len(bounds_filtered_circles)} circles, "
                      f"{white_filter_text}"
                      f"overlap removal final result: {len(filtered_circles)} circles")
        
        if on_progress is not None:
            await on_progress(f"{rect_info}✨ Parallel analysis complete!\n"
                            f"Final result: {len(filtered_circles)} circles detected\n"
                            f"Performance: {max_workers} workers processed {total_combinations} combinations")
    else:
        if on_progress is not None:
            await on_progress(f"{rect_info}✨ Parallel analysis complete!\n"
                            f"Final result: {len(best_circles[0]) if best_circles is not None else 0} circles detected")

    # Create statistics
    param_stats = {
        'parameter_combinations': param_circle_counts,
        'final_circle_count': final_circle_count,
        'total_combinations_tested': len(param_circle_counts),
        'parallel_workers_used': max_workers
    }

    Utils.log_info(f"🏆 Parallel result - Best parameters: {best_params} with score: {best_score:.3f}")
    Utils.log_info(f"⚡ Performance: Used {max_workers} parallel workers for {total_combinations} combinations")
    
    return best_circles, best_params, best_score, param_stats 

def process_single_rectangle(args):
    """
    Process a single rectangle for circle detection in a separate process.
    This enables rectangle-level parallelization for multi-page or multi-rectangle jobs.
    """
    try:
        import asyncio
        
        # Unpack arguments
        (image_bytes, image_shape, rect_data, job_params) = args
        
        # Reconstruct image from bytes
        img = np.frombuffer(image_bytes, dtype=np.uint8).reshape(image_shape)
        
        # Extract rectangle data
        rect = rect_data['rect']
        rect_type = rect_data['rect_type']
        rectangle_info = rect_data['rectangle_info']
        box_id = rect_data['box_id']
        
        # Run the async circle detection function
        # Note: This requires careful handling of the event loop
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        
        try:
            from find_circles import find_circles_cv2
            circles = loop.run_until_complete(
                find_circles_cv2(
                    "", rect, rect_type,
                    img=img,
                    circle_size=job_params.get("circle_size"),
                    dp=job_params.get("dp", 1),
                    darkness_threshold=job_params.get("darkness_threshold", 0),
                    circle_precision_percentage=job_params.get("circle_precision_percentage", 1),
                    param2=job_params.get("param2", 30),
                    on_progress=None,  # Disable progress for parallel processing
                    rectangle_info=rectangle_info,
                    use_parallel=job_params.get("use_parameter_parallel", True),  # Use parameter-level parallelization
                    max_workers=job_params.get("parameter_max_workers", 4)  # Limit workers for nested parallelization
                )
            )
            
            return {
                'box_id': box_id,
                'circles': circles,
                'success': True,
                'rectangle_info': rectangle_info
            }
            
        finally:
            loop.close()
            
    except Exception as e:
        return {
            'box_id': rect_data.get('box_id', 'unknown'),
            'circles': [],
            'success': False,
            'error': str(e),
            'rectangle_info': rect_data.get('rectangle_info', {})
        }

async def find_circles_multiple_rectangles_parallel(cv_image, rectangles_data, job_params, on_progress=None, max_rectangle_workers=None):
    """
    Process multiple rectangles in parallel, with each rectangle potentially using parameter-level parallelization.
    
    Args:
        cv_image: OpenCV image
        rectangles_data: List of rectangle data dictionaries
        job_params: Job parameters dictionary
        on_progress: Progress callback function
        max_rectangle_workers: Number of parallel processes for rectangles (None = auto-detect)
        
    Returns:
        Dictionary mapping box_id to circles
    """
    
    # Determine optimal worker configuration
    total_rectangles = len(rectangles_data)
    
    if max_rectangle_workers is None:
        # Auto-configure based on available CPU cores and number of rectangles
        cpu_count = mp.cpu_count()
        if total_rectangles <= 2:
            # Few rectangles: use parameter-level parallelization with more workers
            max_rectangle_workers = 1
            job_params['use_parameter_parallel'] = True
            job_params['parameter_max_workers'] = min(cpu_count, 8)
        elif total_rectangles <= cpu_count:
            # Medium number: balance rectangle and parameter parallelization
            max_rectangle_workers = min(total_rectangles, cpu_count // 2)
            job_params['use_parameter_parallel'] = True
            job_params['parameter_max_workers'] = 2
        else:
            # Many rectangles: prioritize rectangle-level parallelization
            max_rectangle_workers = min(cpu_count, 6)
            job_params['use_parameter_parallel'] = False
    
    Utils.log_info(f"🚀 Processing {total_rectangles} rectangles with {max_rectangle_workers} workers")
    Utils.log_info(f"📊 Parameter-level parallelization: {'enabled' if job_params.get('use_parameter_parallel', False) else 'disabled'}")
    
    if on_progress is not None:
        param_parallel_text = f"(param-parallel: {job_params.get('parameter_max_workers', 'disabled')} workers)" if job_params.get('use_parameter_parallel', False) else ""
        await on_progress(f"🚀 Processing {total_rectangles} rectangles in parallel\n{max_rectangle_workers} rectangle workers {param_parallel_text}")
    
    # Convert image to bytes for multiprocessing
    image_bytes = cv_image.tobytes()
    image_shape = cv_image.shape
    
    # Prepare arguments for worker processes
    worker_args = []
    for rect_data in rectangles_data:
        worker_args.append((image_bytes, image_shape, rect_data, job_params))
    
    circles_per_box = {}
    completed_count = 0
    
    # Process rectangles in parallel
    with ProcessPoolExecutor(max_workers=max_rectangle_workers) as executor:
        # Submit all rectangle processing tasks
        future_to_box_id = {
            executor.submit(process_single_rectangle, args): args[2]['box_id']
            for args in worker_args
        }
        
        # Process results as they complete
        for future in as_completed(future_to_box_id):
            completed_count += 1
            progress_percent = (completed_count / total_rectangles) * 100
            
            try:
                result = future.result()
                
                if result['success']:
                    circles_per_box[result['box_id']] = result['circles']
                    rect_name = result['rectangle_info'].get('name', 'Unknown')
                    circle_count = len(result['circles'])
                    Utils.log_info(f"✅ Rectangle '{rect_name}' completed: {circle_count} circles detected")
                    
                    if on_progress is not None:
                        await on_progress(f"✅ Completed {completed_count}/{total_rectangles} rectangles ({progress_percent:.1f}%)\nLatest: '{rect_name}' → {circle_count} circles")
                else:
                    box_id = result['box_id']
                    error = result.get('error', 'Unknown error')
                    Utils.log_error(f"❌ Rectangle processing failed for box_id '{box_id}': {error}")
                    circles_per_box[box_id] = []  # Ensure we have an entry
                    
                    if on_progress is not None:
                        await on_progress(f"❌ Error processing rectangle ({completed_count}/{total_rectangles})\nBox ID: {box_id}")
                        
            except Exception as e:
                box_id = future_to_box_id[future]
                Utils.log_error(f"❌ Error retrieving result for box_id '{box_id}': {e}")
                circles_per_box[box_id] = []  # Ensure we have an entry
                continue
    
    if on_progress is not None:
        total_circles = sum(len(circles) for circles in circles_per_box.values())
        await on_progress(f"🎉 All rectangles completed!\nTotal circles detected: {total_circles} across {total_rectangles} rectangles")
    
    Utils.log_info(f"🎉 Parallel rectangle processing complete: {total_rectangles} rectangles processed")
    Utils.log_info(f"📊 Total circles detected: {sum(len(circles) for circles in circles_per_box.values())}")
    
    return circles_per_box 