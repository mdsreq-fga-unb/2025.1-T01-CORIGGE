import 'package:flutter/material.dart';
import 'dart:io';

import '../config/size_config.dart';
import '../config/theme.dart';
import '../widgets/default_button_widget.dart';

class LogoUploadWidget extends StatelessWidget {
  final File? logoFile;
  final String? logoError;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  const LogoUploadWidget({
    super.key,
    required this.logoFile,
    required this.logoError,
    required this.onPickFile,
    required this.onClearFile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(getProportionateScreenWidth(20)),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kSecondary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.image,
                color: kPrimary,
                size: getProportionateScreenWidth(24),
              ),
              SizedBox(width: getProportionateScreenWidth(12)),
              Text(
                'Logo da Escola',
                style: TextStyle(
                  fontSize: getProportionateFontSize(20),
                  fontWeight: FontWeight.bold,
                  color: kOnSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: getProportionateScreenHeight(12)),
          Text(
            'Selecione uma imagem do logo da escola para incluir nos relatórios.',
            style: TextStyle(
              fontSize: getProportionateFontSize(14),
              color: kOnSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: getProportionateScreenHeight(16)),
          if (logoFile != null) ...[
            Container(
              padding: EdgeInsets.all(getProportionateScreenWidth(12)),
              decoration: BoxDecoration(
                color: logoError != null
                    ? kError.withOpacity(0.1)
                    : kPrimary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: logoError != null ? kError : kPrimary,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: getProportionateScreenWidth(40),
                    height: getProportionateScreenHeight(40),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: FileImage(logoFile!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: getProportionateScreenWidth(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          logoFile!.path.split('/').last,
                          style: TextStyle(
                            fontSize: getProportionateFontSize(14),
                            fontWeight: FontWeight.w500,
                            color: logoError != null ? kError : kOnSurface,
                          ),
                        ),
                        if (logoError != null)
                          Text(
                            logoError!,
                            style: TextStyle(
                              fontSize: getProportionateFontSize(12),
                              color: kError,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onClearFile,
                    icon: Icon(
                      Icons.close,
                      color: logoError != null ? kError : kOnSurface,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            DefaultButtonWidget(
              onPressed: onPickFile,
              color: kSecondaryVariant,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image,
                    color: kSurface,
                    size: getProportionateScreenWidth(20),
                  ),
                  SizedBox(width: getProportionateScreenWidth(8)),
                  Text(
                    'SELECIONAR LOGO',
                    style: TextStyle(
                      fontSize: getProportionateFontSize(16),
                      color: kSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
