import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/book.dart';

class BookCard extends StatelessWidget {
  final Book book;
  final bool isDownloaded;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;
  final bool isDownloading;

  const BookCard({
    super.key,
    required this.book,
    this.isDownloaded = false,
    this.onTap,
    this.onPlay,
    this.onDownload,
    this.onDelete,
    this.isDownloading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book cover
              _buildBookCover(context),
              
              SizedBox(width: 16.w),
              
              // Book info
              Expanded(
                child: _buildBookInfo(context),
              ),
              
              SizedBox(width: 12.w),
              
              // Action buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookCover(BuildContext context) {
    return Container(
      width: 60.w,
      height: 90.h,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: book.coverUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book.coverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholderCover(context),
              ),
            )
          : _buildPlaceholderCover(context),
    );
  }

  Widget _buildPlaceholderCover(BuildContext context) {
    return Icon(
      Icons.book,
      size: 24.sp,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  Widget _buildBookInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          book.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        SizedBox(height: 4.h),
        
        Text(
          book.author,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        SizedBox(height: 8.h),
        
        // Status row
        Row(
          children: [
            if (isDownloaded) ...[
              Icon(
                Icons.download_done,
                size: 16.sp,
                color: Colors.green,
              ),
              SizedBox(width: 4.w),
              Text(
                'Downloaded',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ] else ...[
              Icon(
                Icons.cloud_download,
                size: 16.sp,
                color: Theme.of(context).colorScheme.secondary,
              ),
              SizedBox(width: 4.w),
              Text(
                '${book.fileSizeMb.toStringAsFixed(1)} MB',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (isDownloading) {
      return SizedBox(
        width: 24.w,
        height: 24.h,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (isDownloaded) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onPlay != null)
            IconButton(
              onPressed: onPlay,
              icon: Icon(
                Icons.play_arrow,
                color: Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Play',
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
                size: 20.sp,
              ),
              tooltip: 'Delete',
            ),
        ],
      );
    }

    return IconButton(
      onPressed: onDownload,
      icon: Icon(
        Icons.download,
        color: Theme.of(context).colorScheme.primary,
      ),
      tooltip: 'Download',
    );
  }
}