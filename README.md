# Olive Counter

A simple olive fruit counter app powered by a TFLite model.

## Features

- Take a photo with your camera or select an image from your gallery.
- The app will automatically detect and count the number of olives in the image.
- The result is displayed on a separate screen, with bounding boxes around the detected olives.

## Usage

1.  **Load the model:** When you open the app, it will automatically load the TFLite model. Wait for the "Model loaded successfully" message to appear.
2.  **Choose an image:**
    *   Tap the "Take Photo" button to open the camera and take a picture of the olives.
    *   Tap the "Choose from Gallery" button to select an existing image of olives from your device.
3.  **View the results:** The app will process the image and display the total number of olives detected, with bounding boxes drawn around each olive.

## Building from source

To build and run this project, you will need to have the Flutter SDK installed.

1.  Clone the repository:

    ```bash
    git clone https://github.com/sgkouzias/olive_counter.git
    ```

2.  Navigate to the project directory:

    ```bash
    cd olive_counter
    ```

3.  Install the dependencies:

    ```bash
    flutter pub get
    ```

4.  Run the app:

    ```bash
    flutter run
    ```