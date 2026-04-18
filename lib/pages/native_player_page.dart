  Future<void> _savePlayHistory() async {
    final watchDuration = DateTime.now().difference(_startTime);

    await _storageService.addPlayHistory(PlayHistory(
      title: widget.videoTitle,
      cover: '', // 由于这里没有封面，先留空，你可以后续改进
      videoId: widget.videoUrl, // 这里暂用 videoUrl 作为唯一标识
      platform: '360影视',
      lastEpisodeIndex: 0,
      playProgressSeconds: watchDuration.inSeconds,
      watchTime: DateTime.now(),
    ));
  }
