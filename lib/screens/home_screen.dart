// // تحميل المشتركين المحفوظة من الذاكرة مع حماية ضد الخطأ //
void _loadSavedSubscribers() async {
  try {
    final result = await DatabaseService.loadSubscribers();
    if (mounted) {
      setState(() {
        _subscribers = result ?? []; // حماية تامة ضد الـ null لمنع الانهيار
        _isLoadingData = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _subscribers = [];
        _isLoadingData = false;
      });
    }
  }
}
