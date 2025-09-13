import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'cors_proxy_service.dart';

/// Web-specific download service that uses browser's native download capabilities
/// to bypass CORS restrictions when downloading EPUB files from Internet Archive
class WebDownloadService {
  
  /// Downloads a file using the browser's native download mechanism
  /// This bypasses CORS restrictions by letting the browser handle the download
  static Future<String> downloadFileNative(String url, String filename) async {
    debugPrint('🌐 WebDownloadService: Starting native browser download');
    debugPrint('📁 URL: $url');
    debugPrint('📄 Filename: $filename');
    
    try {
      // Create a temporary anchor element for download
      final anchor = html.AnchorElement()
        ..href = url
        ..download = filename
        ..style.display = 'none'
        ..setAttribute('target', '_blank');
      
      // Add to DOM, click, and remove
      html.document.body!.children.add(anchor);
      anchor.click();
      anchor.remove();
      
      debugPrint('✅ WebDownloadService: Browser download initiated');
      
      // Return a placeholder path since the file goes to browser downloads
      return '/browser-downloads/$filename';
      
    } catch (e) {
      debugPrint('❌ WebDownloadService: Native download failed - $e');
      throw Exception('Browser download failed: $e');
    }
  }
  
  /// Checks if a file is available at the given URL using a HEAD request
  /// with no-cors mode to avoid CORS preflight issues
  static Future<Map<String, dynamic>> checkFileAvailability(String url) async {
    debugPrint('🔍 WebDownloadService: Checking file availability - $url');
    
    try {
      // Use fetch with no-cors mode to check availability
      final response = await html.window.fetch(url, {
        'method': 'HEAD',
        'mode': 'no-cors',
        'cache': 'no-cache',
      });
      
      final available = response.status == 200 || response.status == 0; // 0 is returned in no-cors mode
      
      debugPrint('📊 WebDownloadService: File availability check - ${available ? "Available" : "Not Available"}');
      
      return {
        'available': available,
        'status': response.status,
        'url': url,
      };
      
    } catch (e) {
      debugPrint('⚠️ WebDownloadService: Availability check failed - $e');
      return {
        'available': false,
        'error': e.toString(),
        'url': url,
      };
    }
  }
  
  /// Attempts to download using multiple strategies: browser native, then CORS proxy
  static Future<String> downloadWithFallbacks(
    String primaryUrl, 
    String filename,
    {Function(double)? onProgress}
  ) async {
    debugPrint('🔄 WebDownloadService: Trying download with fallbacks');
    
    try {
      // Strategy 1: Try browser native download with multiple URLs
      return await _tryBrowserNativeDownload(primaryUrl, filename, onProgress);
    } catch (e) {
      debugPrint('⚠️ WebDownloadService: Browser native download failed, trying CORS proxy...');
      
      try {
        // Strategy 2: Try CORS proxy download
        return await _tryCorsProxyDownload(primaryUrl, filename, onProgress);
      } catch (proxyError) {
        debugPrint('❌ WebDownloadService: All download strategies failed');
        
        // Provide comprehensive error message with all attempted methods
        throw Exception('''🚫 All Download Methods Failed

🌐 Browser Download: $e
🔄 CORS Proxy: $proxyError

✅ Manual Solutions:
• Open the book's Internet Archive page directly
• Right-click and "Save Link As..." to download
• Use our desktop app for unrestricted downloads
• Check your downloads folder - the file might already be there

🔗 Book URL: $primaryUrl''');
      }
    }
  }

  /// Attempts browser native download with multiple URL patterns
  static Future<String> _tryBrowserNativeDownload(
    String primaryUrl, 
    String filename,
    Function(double)? onProgress,
  ) async {
    final iaId = _extractInternetArchiveId(primaryUrl);
    if (iaId == null) {
      throw Exception('Could not extract Internet Archive ID from URL');
    }
    
    // List of URL patterns to try for Internet Archive EPUBs
    final urlsToTry = [
      primaryUrl, // Original URL
      'https://archive.org/download/$iaId/$iaId.epub',
      'https://archive.org/download/$iaId/${iaId}_djvu.epub',
      'https://archive.org/download/$iaId/${iaId}_text.epub',
      'https://archive.org/download/$iaId/book.epub',
      'https://ia801409.us.archive.org/download/$iaId/$iaId.epub', // Alternative server
      'https://ia601409.us.archive.org/download/$iaId/$iaId.epub', // Alternative server
    ];
    
    for (int i = 0; i < urlsToTry.length; i++) {
      final url = urlsToTry[i];
      debugPrint('🔗 WebDownloadService: Trying browser download ${i + 1}/${urlsToTry.length}: $url');
      
      // Update progress if callback provided
      if (onProgress != null) {
        onProgress((i + 1) / urlsToTry.length * 0.3); // Use 30% of progress for URL testing
      }
      
      try {
        // Check if this URL is available
        final availability = await checkFileAvailability(url);
        
        if (availability['available'] == true) {
          debugPrint('✅ WebDownloadService: Found working URL for browser download: $url');
          
          // Initiate browser download
          final result = await downloadFileNative(url, filename);
          
          // Complete progress
          if (onProgress != null) {
            // Simulate download progress since we can't track browser downloads
            for (double progress = 0.3; progress <= 1.0; progress += 0.1) {
              await Future.delayed(const Duration(milliseconds: 200));
              onProgress(progress);
            }
          }
          
          return result;
        }
        
      } catch (e) {
        debugPrint('❌ WebDownloadService: Browser download URL $url failed - $e');
        continue;
      }
    }
    
    throw Exception('All browser download URLs failed');
  }

  /// Attempts CORS proxy download as fallback
  static Future<String> _tryCorsProxyDownload(
    String primaryUrl,
    String filename,
    Function(double)? onProgress,
  ) async {
    debugPrint('🔄 WebDownloadService: Attempting CORS proxy download');
    
    // Check if proxies are available
    final proxiesAvailable = await CorsProxyService.areProxiesAvailable();
    if (!proxiesAvailable) {
      throw Exception('No CORS proxy services available');
    }
    
    final iaId = _extractInternetArchiveId(primaryUrl);
    if (iaId == null) {
      throw Exception('Could not extract Internet Archive ID from URL');
    }
    
    // Try different URLs with proxy
    final urlsToTry = [
      primaryUrl,
      'https://archive.org/download/$iaId/$iaId.epub',
      'https://archive.org/download/$iaId/${iaId}_djvu.epub',
    ];
    
    for (int i = 0; i < urlsToTry.length; i++) {
      final url = urlsToTry[i];
      debugPrint('🔄 WebDownloadService: Trying CORS proxy ${i + 1}/${urlsToTry.length}: $url');
      
      try {
        // Download via proxy
        final response = await CorsProxyService.downloadWithProxy(url, onProgress: onProgress);
        
        if (response.statusCode == 200) {
          debugPrint('✅ WebDownloadService: CORS proxy download successful');
          
          // Convert to blob and trigger download
          final bytes = await response.stream.toBytes();
          final blob = html.Blob([bytes], 'application/epub+zip');
          final url = html.Url.createObjectUrlFromBlob(blob);
          
          final anchor = html.AnchorElement()
            ..href = url
            ..download = filename
            ..style.display = 'none';
          
          html.document.body!.children.add(anchor);
          anchor.click();
          anchor.remove();
          html.Url.revokeObjectUrl(url);
          
          return '/browser-downloads/$filename';
        }
      } catch (e) {
        debugPrint('❌ WebDownloadService: CORS proxy URL $url failed - $e');
        continue;
      }
    }
    
    throw Exception('All CORS proxy attempts failed');
  }
  
  /// Extracts Internet Archive identifier from various URL formats
  static String? _extractInternetArchiveId(String url) {
    // Handle different Internet Archive URL patterns
    final patterns = [
      RegExp(r'archive\.org/download/([^/]+)/'),
      RegExp(r'ia\d+\.us\.archive\.org/download/([^/]+)/'),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    
    return null;
  }
  
  /// Creates a user-friendly filename from book title
  static String sanitizeFilename(String title, String author) {
    // Remove special characters and limit length
    final sanitized = '$title - $author'
        .replaceAll(RegExp(r'[^\w\s\-_.]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize spaces
        .trim();
    
    // Limit length and add extension
    const maxLength = 200;
    final base = sanitized.length > maxLength 
        ? sanitized.substring(0, maxLength)
        : sanitized;
    
    return '$base.epub';
  }
  
  /// Provides user instructions for browser downloads
  static Map<String, String> getBrowserDownloadInstructions() {
    return {
      'title': '📥 Browser Download Instructions',
      'message': '''
Your book download has been started using your browser's download system.

✅ What to expect:
• Check your browser's download indicator (usually in the toolbar)
• The file will appear in your default Downloads folder
• Download progress will show in your browser

📂 After download:
• The EPUB file can be opened with any e-reader app
• Keep the file - SailorBook will remember it's downloaded

⚠️ If download doesn't start:
• Check if pop-ups are blocked for this site
• Try right-clicking the download link and "Save As..."
• Some browsers may ask for permission first
''',
    };
  }
  
  /// Checks browser compatibility for native downloads
  static bool isBrowserDownloadSupported() {
    try {
      // Check if we have the necessary browser APIs
      return html.AnchorElement().download != null;
    } catch (e) {
      return false;
    }
  }
  
  /// Gets browser-specific download guidance
  static String getBrowserSpecificGuidance() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    
    if (userAgent.contains('chrome')) {
      return 'Chrome: Look for the download arrow in the top-right corner';
    } else if (userAgent.contains('firefox')) {
      return 'Firefox: Downloads appear in the toolbar or Ctrl+Shift+Y';
    } else if (userAgent.contains('safari')) {
      return 'Safari: Downloads appear in the top-right corner';
    } else if (userAgent.contains('edge')) {
      return 'Edge: Look for the download notification at the bottom';
    } else {
      return 'Check your browser\'s download area (usually in the toolbar)';
    }
  }
}