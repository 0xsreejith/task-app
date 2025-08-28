import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingShimmer extends StatelessWidget {
  final bool isList;
  final int itemCount;

  const LoadingShimmer({
    Key? key,
    this.isList = false,
    this.itemCount = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isList) {
      return ListView.builder(
        itemCount: itemCount,
        itemBuilder: (_, __) => _buildPostShimmer(),
      );
    }
    return _buildPostShimmer();
  }

  Widget _buildPostShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: const CircleAvatar(radius: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 80,
                      height: 10,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Image placeholder
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: double.infinity,
              height: 300,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          // Like and comment buttons
          Row(
            children: [
              _buildShimmerButton(40),
              const SizedBox(width: 16),
              _buildShimmerButton(40),
              const Spacer(),
              _buildShimmerButton(24),
            ],
          ),
          const SizedBox(height: 8),
          // Likes count
          _buildShimmerText(100, 16),
          const SizedBox(height: 4),
          // Caption
          _buildShimmerText(200, 16),
          const SizedBox(height: 4),
          _buildShimmerText(150, 16),
          const SizedBox(height: 8),
          // Comments count
          _buildShimmerText(80, 14),
          const SizedBox(height: 8),
          // Post time
          _buildShimmerText(60, 12),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildShimmerButton(double size) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size / 2),
        ),
      ),
    );
  }

  Widget _buildShimmerText(double width, double height) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }
}
