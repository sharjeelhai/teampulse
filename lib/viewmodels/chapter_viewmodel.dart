import 'package:flutter/foundation.dart';
import '../models/chapter_model.dart';
import '../repositories/chapter_repository.dart';

class ChapterViewModel extends ChangeNotifier {
  final ChapterRepository _chapterRepository = ChapterRepository();

  List<ChapterModel> _chapters = [];
  ChapterModel? _selectedChapter;
  bool _isLoading = false;
  String? _errorMessage;

  List<ChapterModel> get chapters => _chapters;
  ChapterModel? get selectedChapter => _selectedChapter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all chapters
  Future<void> loadAllChapters() async {
    try {
      _isLoading = true;
      notifyListeners();

      _chapters = await _chapterRepository.getAllChapters();

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load chapters';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load chapter by ID
  Future<void> loadChapterById(String chapterId) async {
    try {
      _isLoading = true;
      notifyListeners();

      _selectedChapter = await _chapterRepository.getChapterById(chapterId);

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load chapter';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create chapter
  Future<String?> createChapter({
    required String name,
    required String leadId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final chapter = ChapterModel(
        id: '',
        name: name,
        leadId: leadId,
        teamIds: [],
        createdAt: DateTime.now(),
      );

      final chapterId = await _chapterRepository.createChapter(chapter);

      await loadAllChapters();

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      return chapterId;
    } catch (e) {
      _errorMessage = 'Failed to create chapter';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Update chapter
  Future<bool> updateChapter(
    String chapterId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _chapterRepository.updateChapter(chapterId, updates);

      await loadAllChapters();

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update chapter';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete chapter
  Future<bool> deleteChapter(String chapterId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _chapterRepository.deleteChapter(chapterId);

      await loadAllChapters();

      _isLoading = false;
      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete chapter';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get chapter by lead ID
  Future<ChapterModel?> getChapterByLeadId(String leadId) async {
    try {
      return await _chapterRepository.getChapterByLeadId(leadId);
    } catch (e) {
      debugPrint('Error getting chapter by lead ID: $e');
      return null;
    }
  }

  // Listen to chapters stream
  Stream<List<ChapterModel>> getChaptersStream() {
    return _chapterRepository.getAllChaptersStream();
  }
}
