import json
import os
import random
from PIL import Image
import cv2
import numpy as np


def show_image(image, text="image"):
    # Handle different image types
    if len(image.shape) == 2:  # If single channel (grayscale or markers)
        # Convert to 8-bit unsigned if needed
        if image.dtype != np.uint8:
            image = np.uint8(image * (255 / image.max()))
        # Convert to BGR (OpenCV default)
        image = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
    
    # Now convert BGR to RGB for display
    image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    cv2.imshow(text, image)

    # Wait until 'q' is pressed
    while True:
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
    
    cv2.destroyAllWindows()

class CircleIdentificationMethods:
    VC = "VC"
    SIMPLE = "SIMPLE"
    SELF_IMPROVING_AI = "SELF_IMPROVING_AI"

class FlagNames:
    CornerDetection = "corner_detection"
    EdgeDetection = "edge_detection"
    Morphology = "morphology"
    FinalCorners = "final_corners"
    AngleDetection = "angle_detection"
    LegacyAngleDetection = "legacy_angle_detection"
    LegacyShowParamResults = "legacy_show_param_results"
    LegacyShowAverageResult = "legacy_show_average_result"
    LegacyShowFinalImage = "legacy_show_final_image"
    LegacyShowNormalization = "legacy_show_normalization"

class Utils:

    __debug = True

    __image_show_flags = {
        FlagNames.CornerDetection: False,
        FlagNames.EdgeDetection: False,
        FlagNames.Morphology: False,
        FlagNames.FinalCorners: False,
        FlagNames.AngleDetection: False,
        FlagNames.LegacyAngleDetection: False,
        FlagNames.LegacyShowParamResults: False,
        FlagNames.LegacyShowAverageResult: False,
        FlagNames.LegacyShowFinalImage: False,
        FlagNames.LegacyShowNormalization: False,
    }

    @staticmethod
    def show_image(image, text="image"):
        cv2.imshow(text, image)
        while True:
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
        cv2.destroyAllWindows()

    @staticmethod
    def get_version():
        return "0.0.1"

    @staticmethod
    def is_debug():
        return Utils.__debug
    
    @staticmethod
    def set_debug(debug):
        Utils.__debug = debug

    @staticmethod
    def log_error(message):
        print(f"Error: {message}")

    @staticmethod
    def log_info(message):
        print(f"Info: {message}")
        

    @staticmethod
    def log_important_info(message):
        print(f"Important Info: {message}")

    @staticmethod
    def random_hex(length):
        return random.randbytes(length).hex()
    
    @staticmethod
    def load_training_data_for_circles_optimization():
        if not os.path.exists("training_data_circles_optimization.json"):
            with open("training_data_circles_optimization.json", "w") as f:
                json.dump({}, f)
        with open("training_data_circles_optimization.json", "r") as f:
            return json.load(f)
        
    @staticmethod


    @staticmethod
    def save_training_data_for_circles_optimization(training_data):
        with open("training_data_circles_optimization.json", "w") as f:
            json.dump(training_data, f)
        

    @staticmethod
    # Automatic brightness and contrast optimization with optional histogram clipping
    def automatic_brightness_and_contrast(image, clip_hist_percent=1):

        if type(image) == Image.Image:
            image = cv2.cvtColor(np.array(image), cv2.COLOR_BGR2RGB)

        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        
        # Calculate grayscale histogram
        hist = cv2.calcHist([gray],[0],None,[256],[0,256])
        hist_size = len(hist)
        
        # Calculate cumulative distribution from the histogram
        accumulator = []
        accumulator.append(float(hist[0]))
        for index in range(1, hist_size):
            accumulator.append(accumulator[index -1] + float(hist[index]))
        
        # Locate points to clip
        maximum = accumulator[-1]
        clip_hist_percent *= (maximum/100.0)
        clip_hist_percent /= 2.0
        
        # Locate left cut
        minimum_gray = 0
        while accumulator[minimum_gray] < clip_hist_percent:
            minimum_gray += 1
        
        # Locate right cut
        maximum_gray = hist_size -1
        while accumulator[maximum_gray] >= (maximum - clip_hist_percent):
            maximum_gray -= 1
        
        # Calculate alpha and beta values
        alpha = 255 / (maximum_gray - minimum_gray)
        beta = -minimum_gray * alpha
        
        '''
        # Calculate new histogram with desired range and show histogram 
        new_hist = cv2.calcHist([gray],[0],None,[256],[minimum_gray,maximum_gray])
        plt.plot(hist)
        plt.plot(new_hist)
        plt.xlim([0,256])
        plt.show()
        '''

        auto_result = cv2.convertScaleAbs(image, alpha=alpha, beta=beta)
        return (auto_result, alpha, beta)

    @staticmethod
    def set_image_show_flag(flag_name, value):
        if flag_name in Utils.__image_show_flags:
            Utils.__image_show_flags[flag_name] = value

    @staticmethod
    def get_image_show_flag(flag_name):
        return Utils.__image_show_flags.get(flag_name, False)