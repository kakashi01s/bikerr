// In lib/features/chat/presentation/screens/image_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart'; // For downloading the image
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart'; // To get local directory paths
import 'package:permission_handler/permission_handler.dart'; // To request storage permissions
import 'package:path/path.dart'
    as path; // For joining paths and getting filename

class ImageViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String fileName;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.fileName,
  });

  @override
  _ImageViewerScreenState createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  // State variable to indicate if a download is in progress
  bool _isDownloading = false;

  // Function to handle file download
  Future<void> _downloadImage() async {
    // Check if a download is already in progress
    if (_isDownloading) {
      print("ImageViewerScreen: Download already in progress.");
      return; // Prevent multiple download attempts
    }

    // Request storage permission
    var status = await Permission.storage.request();

    if (status.isGranted) {
      // Permission granted, proceed with download
      setState(() {
        _isDownloading = true; // Set downloading state to true
      });

      try {
        // Get the application's documents directory for saving the file
        // Note: For shared files like downloads, consider using getDownloadsDirectory()
        // if targeting Android 11+ and configured correctly in manifest.
        // getApplicationDocumentsDirectory is app-specific storage.
        final directory = await getApplicationDocumentsDirectory();
        final savePath = path.join(directory.path, widget.fileName);

        // Using Dio for downloading
        final dio = Dio();

        // Show a downloading indicator or message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloading ${widget.fileName}...')),
          );
        }

        // Perform the download
        await dio.download(
          widget.imageUrl,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              // You can update a progress indicator here if needed
              print(
                'Download progress: ${(received / total * 100).toStringAsFixed(0)}%',
              );
            }
          },
        );

        // Download successful
        print("ImageViewerScreen: Download complete. Saved to: $savePath");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded ${widget.fileName}'),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  // Open the downloaded file using open_file_plus
                  OpenFilex.open(savePath);
                },
              ),
            ),
          );
        }
      } catch (e) {
        // Handle download errors
        print('ImageViewerScreen: Error downloading file: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to download ${widget.fileName}')),
          );
        }
      } finally {
        // Ensure downloading state is reset regardless of success or failure
        if (mounted) {
          setState(() {
            _isDownloading = false;
          });
        }
      }
    } else {
      // Handle permission denied
      print("ImageViewerScreen: Storage permission denied.");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar to show filename and download button
      appBar: AppBar(
        title: Text(widget.fileName), // Display the filename as the title
        backgroundColor:
            Colors.black, // Dark background for image viewer AppBar
        foregroundColor: Colors.white, // White text/icons
        actions: [
          // Download button
          IconButton(
            icon:
                _isDownloading
                    ? const SizedBox(
                      // Show a small loading indicator when downloading
                      width: 24.0,
                      height: 24.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(
                      Icons.download,
                    ), // Show download icon when not downloading
            onPressed:
                _isDownloading
                    ? null
                    : _downloadImage, // Disable button while downloading
            tooltip:
                _isDownloading
                    ? 'Downloading...'
                    : 'Download Image', // Tooltip text
          ),
        ],
      ),
      // Body to display the image with zoom/pan capabilities
      body: Container(
        color: Colors.black, // Black background for the image view area
        child: Center(
          // InteractiveViewer allows zooming and panning
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(20.0),
            minScale: 0.1,
            maxScale: 4.0,
            child: Image.network(
              widget.imageUrl,
              loadingBuilder: (
                BuildContext context,
                Widget child,
                ImageChunkEvent? loadingProgress,
              ) {
                if (loadingProgress == null) {
                  return child; // Image is loaded, display it
                }
                // Show a progress indicator while the image is loading
                return Center(
                  child: CircularProgressIndicator(
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null, // Indeterminate progress if total size is unknown
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                );
              },
              errorBuilder: (
                BuildContext context,
                Object exception,
                StackTrace? stackTrace,
              ) {
                // Show an error icon if the image fails to load
                print(
                  'ImageViewerScreen: Failed to load image from URL: ${widget.imageUrl}, Exception: $exception',
                );
                return const Center(
                  child: Icon(Icons.error, color: Colors.red, size: 50.0),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
