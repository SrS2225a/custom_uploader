# Building the flutter project

## Prerequisites
1. Begin by cloning the repository:

   ```bash
   git clone https://github.com/SrS2225a/custom_uploader.git
   cd custom_uploader
   ```
   
 2. Instead of installing flutter manually, we use a submodule of it. We use the Flutter submodule to ensure that everyone is working with the same version of Flutter, preventing issues caused by mismatched versions. It also simplifies setup, as developers don't need to worry about installing the correct version of Flutter. You will need to initialize and update the submodule before building:
    ```bash
    git submodule init
    git submodule update
    flutter/bin/flutter doctor -v #This will check if we have installed the flutter submodule correctly
    ```

## Building the project
1. To build the project, run the following commands:
   ```bash
   flutter/bin/flutter pub get
   flutter/bin/flutter pub run build_runner build -d #This will generate/update any code based on annotations in the project
   flutter/bin/flutter build apk --release
   ```

 That's it! You should now have the project built and ready to run.
