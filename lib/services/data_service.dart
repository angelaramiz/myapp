import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/video_link.dart';
import '../models/folder.dart';

class DataService {
  static const String _videoLinksKey = 'video_links';
  static const String _foldersKey = 'folders';

  // Folders methods
  Future<List<Folder>> getFolders() async {
    final prefs = await SharedPreferences.getInstance();
    final foldersJson = prefs.getStringList(_foldersKey) ?? [];

    return foldersJson
        .map((json) => Folder.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> saveFolder(Folder folder) async {
    final prefs = await SharedPreferences.getInstance();
    List<Folder> folders = await getFolders();

    // Check if folder already exists
    final folderIndex = folders.indexWhere((f) => f.id == folder.id);

    if (folderIndex >= 0) {
      folders[folderIndex] = folder;
    } else {
      folders.add(folder);
    }

    final foldersJson = folders
        .map((folder) => jsonEncode(folder.toJson()))
        .toList();

    await prefs.setStringList(_foldersKey, foldersJson);
  }

  Future<void> deleteFolder(String folderId) async {
    final prefs = await SharedPreferences.getInstance();
    List<Folder> folders = await getFolders();

    folders.removeWhere((folder) => folder.id == folderId);

    final foldersJson = folders
        .map((folder) => jsonEncode(folder.toJson()))
        .toList();

    await prefs.setStringList(_foldersKey, foldersJson);

    // Delete all video links in this folder
    List<VideoLink> videoLinks = await getVideoLinks();
    videoLinks.removeWhere((link) => link.folderId == folderId);

    final videoLinksJson = videoLinks
        .map((link) => jsonEncode(link.toJson()))
        .toList();

    await prefs.setStringList(_videoLinksKey, videoLinksJson);
  }

  // Video Links methods
  Future<List<VideoLink>> getVideoLinks() async {
    final prefs = await SharedPreferences.getInstance();
    final linksJson = prefs.getStringList(_videoLinksKey) ?? [];

    return linksJson
        .map((json) => VideoLink.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<List<VideoLink>> getVideoLinksByFolder(String folderId) async {
    final links = await getVideoLinks();
    return links.where((link) => link.folderId == folderId).toList();
  }

  Future<void> saveVideoLink(VideoLink videoLink) async {
    final prefs = await SharedPreferences.getInstance();
    List<VideoLink> links = await getVideoLinks();

    // Check if link already exists
    final linkIndex = links.indexWhere((link) => link.id == videoLink.id);

    if (linkIndex >= 0) {
      links[linkIndex] = videoLink;
    } else {
      links.add(videoLink);
    }

    final linksJson = links.map((link) => jsonEncode(link.toJson())).toList();

    await prefs.setStringList(_videoLinksKey, linksJson);
  }

  Future<void> deleteVideoLink(String videoLinkId) async {
    final prefs = await SharedPreferences.getInstance();
    List<VideoLink> links = await getVideoLinks();

    links.removeWhere((link) => link.id == videoLinkId);

    final linksJson = links.map((link) => jsonEncode(link.toJson())).toList();

    await prefs.setStringList(_videoLinksKey, linksJson);
  }

  // Notifications methods
  Future<List<VideoLink>> getReminders() async {
    final links = await getVideoLinks();
    return links.where((link) => link.reminder != null).toList();
  }
}
