import 'package:flutter_test/flutter_test.dart';
import 'package:speech2sign/features/cafe_pos/domain/services/queue_pager_service.dart';

void main() {
  late QueuePagerService pagerService;

  setUp(() {
    pagerService = QueuePagerService();
  });

  group('QueuePagerService - Number formatting', () {
    test('converts numbers to Indonesian words', () {
      expect(QueuePagerService.numberToIndonesianWords(1), 'satu');
      expect(QueuePagerService.numberToIndonesianWords(10), 'sepuluh');
      expect(QueuePagerService.numberToIndonesianWords(11), 'sebelas');
      expect(QueuePagerService.numberToIndonesianWords(12), 'dua belas');
      expect(QueuePagerService.numberToIndonesianWords(25), 'dua puluh lima');
      expect(QueuePagerService.numberToIndonesianWords(100), 'seratus');
      expect(QueuePagerService.numberToIndonesianWords(108), 'seratus delapan');
      expect(
        QueuePagerService.numberToIndonesianWords(215),
        'dua ratus lima belas',
      );
    });

    test('formats queue number with prefix correctly', () {
      expect(
        QueuePagerService.formatQueueNumberForSpeech('A-108'),
        'A seratus delapan',
      );
      expect(
        QueuePagerService.formatQueueNumberForSpeech('B-12'),
        'B dua belas',
      );
    });
  });

  group('QueuePagerService - Call generation', () {
    test('generates announcement text for hearing customer with name', () {
      final text = pagerService.generateHearingCallText(
        queueNumber: 'A-108',
        customerName: 'Rian',
      );
      expect(
        text,
        'Pesanan nomor A seratus delapan atas nama Rian sudah siap diambil di meja bar. Terima kasih.',
      );
    });

    test('generates announcement text for hearing customer without name', () {
      final text = pagerService.generateHearingCallText(
        queueNumber: 'A-05',
        customerName: '',
      );
      expect(
        text,
        'Pesanan nomor A lima sudah siap diambil di meja bar. Terima kasih.',
      );
    });

    test('dispatches hearing call event correctly', () async {
      final event = await pagerService.callHearingCustomer(
        queueNumber: 'A-108',
        customerName: 'Rian',
      );
      expect(event.isHearingTarget, isTrue);
      expect(event.queueNumber, 'A-108');
      expect(event.customerName, 'Rian');
      expect(event.speechText, contains('A seratus delapan'));
    });

    test('dispatches deaf call event with sign video and haptic flag', () async {
      final event = await pagerService.callDeafCustomer(
        queueNumber: 'A-108',
        customerName: 'Rian',
        triggerHaptics: false, // In test environment
      );
      expect(event.isHearingTarget, isFalse);
      expect(event.signVideoKeyword, 'PESANAN SIAP DIAMBIL');
      expect(event.queueNumber, 'A-108');
    });
  });
}
