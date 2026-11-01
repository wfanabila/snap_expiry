
import 'package:flutter/material.dart';

import '../../../../core/utils/date_utils.dart';
import '../../domain/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.warningDays = 7,
  });

  final Product product;
  final VoidCallback onTap;
  final int warningDays;

  @override
  Widget build(BuildContext context) {
    final status = ExpiryDateUtils.statusFor(
      product.expiryDate,
      thresholdDays: warningDays,
    );

    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    switch (status) {
      case ExpiryStatus.expired:
        statusColor = Colors.red;
        statusText = 'Expired';
        statusIcon = Icons.error_outline;
      case ExpiryStatus.expiringSoon:
        statusColor = Colors.orange.shade800;
        statusText = 'Expiring soon';
        statusIcon = Icons.warning_amber_rounded;
      case ExpiryStatus.safe:
        statusColor = Colors.green.shade700;
        statusText = 'Safe';
        statusIcon = Icons.check_circle_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category} • Qty: ${product.quantity}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Expiry: ${ExpiryDateUtils.formatDate(product.expiryDate)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(statusIcon, color: statusColor, size: 16),
                        const SizedBox(width: 5),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
