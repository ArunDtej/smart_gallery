# Smart Gallery - Incomplete (AI-Powered Image Search)

This Flutter app, Smart Gallery, is a work in progress, but it showcases a powerful AI-driven image similarity search feature. Users can query their image library by selecting a reference image, and the app will return visually similar images.

## Key Features (Implemented):

*   **AI-Powered Similarity Search:** The core feature is the ability to search for similar images using a selected reference image.
*   **TFLite Integration:** The app utilizes a TensorFlow Lite (TFLite) version of MobileNet v3 to generate image embeddings.
*   **Efficient Embedding Generation:** The app is optimized for performance, generating embeddings at a rate of 200+ images per minute on an average device. This one-time embedding generation happens in the background.
*   **Cosine Similarity Search:** Image similarity is determined using the cosine similarity between the generated embeddings.

## How it Works:

1.  **One-Time Embedding Generation:** When the app is first used (or when new images are added), the app processes each image in the user's gallery. It uses the TFLite MobileNet v3 model to create a numerical representation (embedding) of each image. This process happens in the background to avoid blocking the user interface.
2.  **Similarity Search:** When the user selects a reference image, the app calculates the cosine similarity between the embedding of the reference image and the embeddings of all other images in the gallery.
3.  **Result Display:** The app displays the images sorted by their similarity score, with the most similar images appearing first.

## Technologies Used:

*   **Flutter:** For cross-platform mobile development.
*   **TensorFlow Lite (TFLite):** For on-device machine learning inference.
*   **MobileNet v3:** A lightweight convolutional neural network optimized for mobile devices.
*   **Cosine Similarity:** A metric used to measure the similarity between two non-zero vectors.

## Current Status:

This app is currently incomplete. The following features are planned but not yet implemented:

*   **User Interface/User Experience (UI/UX) Enhancements:** The current UI is basic and needs significant improvement.
*   **Background Processing Management:** More robust handling of background embedding generation is needed, including error handling and progress updates.
*   **Image Caching:** Implementing image caching to improve performance and reduce loading times.
*   **Error Handling and Edge Cases:** More comprehensive error handling and handling of edge cases (e.g., no images in the gallery, unsupported image formats).

You are welcome to go through the codebase or use the models in your application as I am abandoning the project :')

I am implemented until multiitem select on images, I wanted to add, delete, share and some other functionalities, along with text based search that can search for images based on text. But I don't have the time or the will to do it, so posting it here hoping if this would be useful to any of you guys!
