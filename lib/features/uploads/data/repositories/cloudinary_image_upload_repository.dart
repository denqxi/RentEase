import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/cloudinary_config.dart';
import '../../domain/entities/uploaded_image.dart';
import '../../domain/repositories/image_upload_repository.dart';

/// image_picker + UNSIGNED Cloudinary upload (multipart POST, one image per
/// request). No secret is used or stored in the app.
class CloudinaryImageUploadRepository implements ImageUploadRepository {
  CloudinaryImageUploadRepository({ImagePicker? picker, http.Client? client})
    : _picker = picker ?? ImagePicker(),
      _client = client ?? http.Client();

  final ImagePicker _picker;
  final http.Client _client;

  bool _isDoc(ImageKind k) => k == ImageKind.verificationDocument;

  @override
  Future<String?> pick(ImageKind kind, PickSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == PickSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: _isDoc(kind)
            ? CloudinaryConfig.documentMaxWidth
            : CloudinaryConfig.propertyPhotoMaxWidth,
        imageQuality: _isDoc(kind)
            ? CloudinaryConfig.documentQuality
            : CloudinaryConfig.propertyPhotoQuality,
      );
      return file?.path;
    } catch (_) {
      throw const ImageUploadException(
        'Could not open the camera or gallery. Check app permissions and try again.',
      );
    }
  }

  @override
  Future<UploadedImage> upload(ImageKind kind, String path) async {
    if (!CloudinaryConfig.isConfigured) {
      throw const ImageUploadException(
        'Image upload is not configured yet. Please contact support.',
      );
    }
    // Web: picked path is a blob URL, so dart:io File can't read it.
    Uint8List? webBytes;
    final int size;
    try {
      if (kIsWeb) {
        webBytes = await XFile(path).readAsBytes();
        size = webBytes.length;
      } else {
        size = await File(path).length();
      }
    } catch (_) {
      throw const ImageUploadException(
        'Could not read that image. Pick another.',
      );
    }
    final cap = _isDoc(kind)
        ? CloudinaryConfig.maxDocumentBytes
        : CloudinaryConfig.maxPropertyPhotoBytes;
    if (size > cap) {
      throw ImageUploadException(
        'That image is too large (max ${cap ~/ (1024 * 1024)} MB). Pick a smaller one.',
      );
    }

    final request = http.MultipartRequest('POST', CloudinaryConfig.uploadUri)
      ..fields['upload_preset'] = _isDoc(kind)
          ? CloudinaryConfig.documentPreset
          : CloudinaryConfig.propertyPhotoPreset
      ..fields['folder'] = _isDoc(kind)
          ? CloudinaryConfig.documentFolder
          : CloudinaryConfig.propertyPhotoFolder
      ..files.add(
        kIsWeb
            ? http.MultipartFile.fromBytes(
                'file',
                webBytes!,
                filename: 'upload.jpg',
              )
            : await http.MultipartFile.fromPath('file', path),
      );

    try {
      final streamed = await _client
          .send(request)
          .timeout(CloudinaryConfig.uploadTimeout);
      final res = await http.Response.fromStream(streamed);
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body is Map) {
        final url = body['secure_url'] as String?;
        final id = body['public_id'] as String?;
        if (url != null && id != null) {
          return UploadedImage(url: url, publicId: id);
        }
      }
      throw const ImageUploadException('Upload failed. Please try again.');
    } on ImageUploadException {
      rethrow;
    } on TimeoutException {
      throw const ImageUploadException(
        'Upload timed out. Check your connection and retry.',
      );
    } on SocketException {
      throw const ImageUploadException(
        'No internet connection. Check it and retry.',
      );
    } on http.ClientException {
      throw const ImageUploadException(
        'Network error. Check your connection and retry.',
      );
    } catch (_) {
      throw const ImageUploadException('Upload failed. Please try again.');
    }
  }
}
