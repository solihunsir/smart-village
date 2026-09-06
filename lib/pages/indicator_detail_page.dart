// File: lib/pages/indicator_detail_page.dart

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart'; // BARU: Import Provider
import '../providers/theme_provider.dart'; // BARU: Import ThemeProvider
import '../models/annual_category_data.dart';
import '../services/indicator_service.dart';

// Warna chart default (akan ditimpa/diabaikan, tapi didefinisikan di sini)
const List<Color> chartColors = [
  Color(0xFF4CAF50),
  Color(0xFF2196F3),
  Color(0xFFFF9800),
  Color(0xFF9C27B0),
  Color(0xFFF44336),
];

enum IndicatorCategory { population, education, work, health }

class IndicatorDetailPage extends StatefulWidget {
  final String categoryTitle;
  final String variableName;
  final int categoryId;
  final int variableCategoryId;

  const IndicatorDetailPage({
    super.key,
    required this.categoryTitle,
    required this.variableName,
    required this.categoryId,
    required this.variableCategoryId,
  });

  factory IndicatorDetailPage.fromVariable({
    required String categoryTitle,
    required String variableName,
    required int categoryId,
    required int variableCategoryId,
  }) {
    return IndicatorDetailPage(
      categoryTitle: categoryTitle,
      variableName: variableName,
      categoryId: categoryId,
      variableCategoryId: variableCategoryId,
    );
  }

  @override
  State<IndicatorDetailPage> createState() => _IndicatorDetailPageState();
}

class TooltipData {
  final int index;
  final Offset position;
  final String label;
  final double value;
  final String period;

  TooltipData({
    required this.index,
    required this.position,
    required this.label,
    required this.value,
    required this.period,
  });
}

class _IndicatorDetailPageState extends State<IndicatorDetailPage> {
  String _selectedChartType = 'Diagram Garis';

  final TextEditingController _startPeriodController = TextEditingController();
  final TextEditingController _endPeriodController = TextEditingController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  List<int> _availableYears = [];

  List<AnnualCategoryData> _chartData = [];
  bool _isLoading = true;
  String _errorMessage = '';

  String _yearError = '';

  TooltipData? _currentTooltip;

  bool _shouldShowYearColumn = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _startPeriodController.dispose();
    _endPeriodController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitialData() async {
    if (!mounted) return;
    setState(() {
      _yearError = '';
      _errorMessage = '';
      _isLoading = true;
      _chartData = [];
      _selectedStartDate = null;
      _selectedEndDate = null;
      _startPeriodController.clear();
      _endPeriodController.clear();
      _currentTooltip = null;
    });

    if (widget.variableCategoryId <= 0) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Variabel ID tidak valid.';
        });
      }
      return;
    }

    final response = await IndicatorService.getAnnualCategoryData(
      categoryId: widget.categoryId,
      variableCategoryId: widget.variableCategoryId,
      periodStart: null,
      periodEnd: null,
    );

    if (mounted) {
      if (response != null && response.success && response.data.isNotEmpty) {
        List<AnnualCategoryData> allData = response.data;
        allData.sort((a, b) => a.periodStart.compareTo(b.periodStart));

        final String firstPeriodStartStr = allData.first.periodStart;
        final String lastPeriodEndStr = allData.last.periodEnd;

        _shouldShowYearColumn = allData.any((d) => d.year > 0);

        try {
          _selectedStartDate = DateTime.parse(firstPeriodStartStr);
          _selectedEndDate = DateTime.parse(lastPeriodEndStr);

          // Inisialisasi controller teks setelah data pertama dimuat
          _startPeriodController.text =
              DateFormat('MMMM yyyy', 'id_ID').format(_selectedStartDate!);
          _endPeriodController.text =
              DateFormat('MMMM yyyy', 'id_ID').format(_selectedEndDate!);
        } catch (_) {
          final int minYear = allData.first.year;
          final int maxYear = allData.last.year;
          _selectedStartDate = DateTime(minYear, 1, 1);
          _selectedEndDate = DateTime(maxYear, 12, 31);
        }

        setState(() {
          _chartData = allData;
          _errorMessage = '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response?.message ??
              'Tidak ada data tersedia untuk variabel ini.';
          _isLoading = false;
          _chartData = [];
          _shouldShowYearColumn = false;
        });
      }

      await _fetchAvailableYears();
    }
  }

  Future<void> _fetchAvailableYears() async {
    try {
      final years = await IndicatorService.getAvailableYears(
        categoryId: widget.categoryId,
      );
      if (mounted) {
        setState(() {
          _availableYears = years;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _yearError = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _fetchChartData({bool isInitial = false}) async {
    if (widget.variableCategoryId <= 0) {
      if (!isInitial && mounted) {
        setState(() {
          _errorMessage = 'Variabel ID tidak valid untuk mengambil data.';
        });
      }
      return;
    }

    if (_selectedStartDate == null || _selectedEndDate == null) {
      if (!isInitial && mounted) {
        setState(() {
          _errorMessage = 'Periode awal dan akhir harus dipilih.';
        });
      }
      if (!isInitial) return;
    }

    if (_selectedStartDate != null &&
        _selectedEndDate != null &&
        _selectedStartDate!.isAfter(_selectedEndDate!)) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Periode awal tidak boleh melebihi periode akhir.';
          _chartData = [];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _chartData = [];
        _currentTooltip = null;
      });
    }

    final String? periodStart = _selectedStartDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedStartDate!)
        : null;

    final String? periodEnd = _selectedEndDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedEndDate!)
        : null;

    final response = await IndicatorService.getAnnualCategoryData(
      categoryId: widget.categoryId,
      variableCategoryId: widget.variableCategoryId,
      periodStart: periodStart,
      periodEnd: periodEnd,
    );

    if (mounted) {
      setState(() {
        if (response != null && response.success) {
          _chartData = response.data;
          _chartData.sort((a, b) => a.periodStart.compareTo(b.periodStart));
          _shouldShowYearColumn = _chartData.any((d) => d.year > 0);
          _errorMessage = '';
        } else {
          _errorMessage =
              'Gagal memuat data chart: ${response?.message ?? "Kesalahan koneksi atau API."}';
          _chartData = [];
          _shouldShowYearColumn = false;
        }
        _isLoading = false;
      });
    }
  }

  String getVariableName(int id) {
    return widget.variableName;
  }

  List<String> getChartLabels(List<AnnualCategoryData> data, String chartType) {
    return data.map((d) {
      try {
        return DateFormat('MMM yyyy').format(DateTime.parse(d.periodStart));
      } catch (_) {
        return d.year.toString();
      }
    }).toList();
  }

  void _handleChartTap(Offset position, Size chartSize, double axisLabelWidth) {
    if (_chartData.isEmpty || _chartData.length < 1) {
      setState(() => _currentTooltip = null);
      return;
    }

    final maxDataValue = _chartData.map((d) => d.value).reduce(max) * 1.2;
    if (maxDataValue <= 0) {
      setState(() => _currentTooltip = null);
      return;
    }

    final chartWidth = chartSize.width - axisLabelWidth;
    final chartHeight = chartSize.height - 40;
    final chartRect = Rect.fromLTWH(axisLabelWidth, 0, chartWidth, chartHeight);
    final itemWidth =
        chartWidth / (_chartData.length > 1 ? _chartData.length - 1 : 1);

    int nearestIndex = -1;
    double minDistanceSquared = double.infinity;

    for (int index = 0; index < _chartData.length; index++) {
      final x = chartRect.left + (index * itemWidth);
      final y = chartRect.bottom -
          (_chartData[index].value / maxDataValue) * chartHeight;
      final point = Offset(x, y);

      final dx = position.dx - point.dx;
      final dy = position.dy - point.dy;
      final distanceSquared = dx * dx + dy * dy;

      if (distanceSquared < minDistanceSquared) {
        minDistanceSquared = distanceSquared;
        nearestIndex = index;
      }
    }

    if (minDistanceSquared > 625 || nearestIndex == -1) {
      setState(() => _currentTooltip = null);
      return;
    }

    final clickedData = _chartData[nearestIndex];

    final pointX = chartRect.left + (nearestIndex * itemWidth);
    final pointY =
        chartRect.bottom - (clickedData.value / maxDataValue) * chartHeight;

    String periodText;
    try {
      final periodStart = DateFormat(
        'MMM yyyy',
      ).format(DateTime.parse(clickedData.periodStart));
      final periodEnd = DateFormat(
        'MMM yyyy',
      ).format(DateTime.parse(clickedData.periodEnd));
      periodText = '$periodStart - $periodEnd';
    } catch (_) {
      periodText = 'Tahun ${clickedData.year}';
    }

    setState(() {
      _currentTooltip = TooltipData(
        index: nearestIndex,
        position: Offset(pointX, pointY),
        label: clickedData.variableCategory?.name ?? widget.variableName,
        value: clickedData.value,
        period: periodText,
      );
    });
  }

  Widget _buildManualPeriodInput({
    required TextEditingController controller,
    required String hint,
    required bool isDisabled,
    VoidCallback? onTap,
    required Color primaryColor, // BARU: Menerima primaryColor
  }) {
    final bool hasText = controller.text.isNotEmpty;

    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade200 : Colors.grey.shade100,
          border: Border.all(
            color: hasText && !isDisabled
                ? primaryColor
                : Colors.grey.shade300, // MENGGANTI: Warna border
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                hasText ? controller.text : hint,
                style: TextStyle(
                  fontSize: 14,
                  color: isDisabled
                      ? Colors.grey.shade600
                      : (hasText ? Colors.black : Colors.black54),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.calendar_today,
              size: 16,
              color: isDisabled
                  ? Colors.grey
                  : primaryColor, // MENGGANTI: Warna ikon
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectManualDateRange() async {
    final DateTime now = DateTime.now();

    DateTime initialStart = _selectedStartDate ?? DateTime(now.year - 3, 1, 1);
    DateTime initialEnd =
        _selectedEndDate ?? DateTime(now.year, now.month, now.day);

    if (initialStart.isAfter(initialEnd)) {
      initialStart = initialEnd;
    }

    // BARU: Ambil warna tema untuk builder date picker
    final primaryColor = context.read<ThemeProvider>().primaryColor;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('id', 'ID'),
      saveText: 'Pilih',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData(
            // MENGGANTI: Warna tema untuk DatePicker
            primaryColor: primaryColor,
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: Localizations.override(
            context: context,
            delegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            locale: const Locale('id', 'ID'),
            child: child ?? Container(),
          ),
        );
      },
    );

    if (picked != null && mounted) {
      final formattedStart = DateFormat(
        'MMMM yyyy',
        'id_ID',
      ).format(picked.start);
      final formattedEnd = DateFormat('MMMM yyyy', 'id_ID').format(picked.end);

      setState(() {
        _startPeriodController.text = formattedStart;
        _endPeriodController.text = formattedEnd;

        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });

      _fetchChartData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Ambil warna dari ThemeProvider
    final primaryColor = context.watch<ThemeProvider>().primaryColor;

    final pageTitle = widget.variableName;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          // MENGGANTI: Warna ikon hardcoded
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          pageTitle,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSection(primaryColor), // Meneruskan primaryColor
            const SizedBox(height: 24),
            _buildChartSection(primaryColor), // Meneruskan primaryColor
            const SizedBox(height: 24),
            const Text(
              'Data Variabel',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            _buildDataTableSection(primaryColor), // Meneruskan primaryColor
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(Color primaryColor) {
    if (_isLoading && _chartData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          // MENGGANTI: Warna loading hardcoded
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (widget.variableCategoryId <= 0) {
      return _buildEmptyStateBox(primaryColor); // Meneruskan primaryColor
    }

    final bool isSearchDisabled = widget.variableCategoryId <= 0;

    final String startHint = _startPeriodController.text.isNotEmpty
        ? _startPeriodController.text
        : 'Tahun Awal';

    final String endHint = _endPeriodController.text.isNotEmpty
        ? _endPeriodController.text
        : 'Tahun Akhir';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildManualPeriodInput(
                controller: _startPeriodController,
                hint: startHint,
                isDisabled: isSearchDisabled,
                onTap: _selectManualDateRange,
                primaryColor: primaryColor, // Meneruskan primaryColor
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildManualPeriodInput(
                controller: _endPeriodController,
                hint: endHint,
                isDisabled: isSearchDisabled,
                onTap: _selectManualDateRange,
                primaryColor: primaryColor, // Meneruskan primaryColor
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSearchDisabled
                    ? Colors.grey.shade400
                    : primaryColor, // MENGGANTI: Warna tombol hardcoded
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 24),
                onPressed: isSearchDisabled ? null : _fetchChartData,
              ),
            ),
          ],
        ),
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              'Error: $_errorMessage',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyStateBox(Color primaryColor) {
    String specificError = '';
    if (widget.variableCategoryId <= 0) {
      specificError += 'Variabel ID tidak valid.';
    }
    if (_yearError.isNotEmpty) {
      specificError += 'Gagal memuat Data Tahun: $_yearError. ';
    }

    final message = specificError.isNotEmpty
        ? 'Terjadi kesalahan sistem:\n${specificError.trim()}'
        : 'Tidak ada data yang dapat ditampilkan untuk variabel ini. Mohon hubungi administrator.';

    // Menghitung warna turunan untuk Error/Empty Box
    final errorColor = Colors.red.shade700;
    final boxColor = specificError.isNotEmpty
        ? Colors.red.shade50
        : primaryColor.withOpacity(0.1);
    final borderColor = specificError.isNotEmpty
        ? Colors.red.shade200
        : primaryColor.withOpacity(0.3);
    final iconTextColor = specificError.isNotEmpty ? errorColor : primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: boxColor, // MENGGANTI: Warna latar
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor, // MENGGANTI: Warna border
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                specificError.isNotEmpty
                    ? Icons.warning_amber
                    : Icons.info_outline,
                color: iconTextColor, // MENGGANTI: Warna ikon
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                specificError.isNotEmpty
                    ? 'Kesalahan Memuat Data'
                    : 'Data Kosong',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: iconTextColor, // MENGGANTI: Warna teks header
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: TextStyle(
              color: specificError.isNotEmpty
                  ? Colors.red.shade700
                  : primaryColor
                      .withOpacity(0.8), // MENGGANTI: Warna teks konten
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterInfo(Color primaryColor) {
    if (_startPeriodController.text.isEmpty ||
        _endPeriodController.text.isEmpty) {
      return Container();
    }

    // MENGGANTI: Warna latar dan ikon filter info
    final infoBgColor = primaryColor.withOpacity(0.1);

    final periodText =
        '${_startPeriodController.text} - ${_endPeriodController.text}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: infoBgColor, // MENGGANTI: Warna latar
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: primaryColor, size: 20), // MENGGANTI: Warna ikon
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Filter Periode: $periodText',
              style: TextStyle(
                color: primaryColor, // MENGGANTI: Warna teks
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(Color primaryColor) {
    if (widget.variableCategoryId <= 0) {
      return Container();
    }

    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          // MENGGANTI: Warna loading hardcoded
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Chart tidak dapat dimuat: $_errorMessage',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:
                  primaryColor.withOpacity(0.6), // MENGGANTI: Warna teks error
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    const double axisLabelWidth = 35.0;

    final double maxVal = _chartData.map((d) => d.value).isEmpty
        ? 1.0
        : _chartData.map((d) => d.value).reduce(max);
    final double safeMaxValue = maxVal * 1.2;

    return Column(
      children: [
        _buildFilterInfo(primaryColor), // Meneruskan primaryColor
        AspectRatio(
          aspectRatio: 1.5,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartSize = constraints.biggest;

              return GestureDetector(
                onTapDown: (details) {
                  _handleChartTap(
                    details.localPosition,
                    chartSize,
                    axisLabelWidth,
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Stack(
                      children: [
                        _chartData.isEmpty
                            ? const Center(
                                child: Text(
                                  'Tidak ada data tersedia untuk periode ini.',
                                ),
                              )
                            : CustomPaint(
                                painter: ChartPainter(
                                  data: _chartData.map((d) => d.value).toList(),
                                  labels: getChartLabels(
                                    _chartData,
                                    _selectedChartType,
                                  ),
                                  maxValue: safeMaxValue,
                                  chartType: 'Diagram Garis',
                                  currentTooltip: _currentTooltip,
                                  primaryColor:
                                      primaryColor, // BARU: Meneruskan warna
                                ),
                                child: Container(),
                              ),
                        if (_currentTooltip != null)
                          Positioned(
                            left: _currentTooltip!.position.dx,
                            top: _currentTooltip!.position.dy,
                            child: _buildTooltipWidget(_currentTooltip!,
                                primaryColor), // Meneruskan primaryColor
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTooltipWidget(TooltipData tooltipData, Color primaryColor) {
    const double offsetX = -5;
    const double offsetY = -60;

    return Transform.translate(
      offset: Offset(offsetX, offsetY),
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 3),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tooltipData.period,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primaryColor, // MENGGANTI: Warna dot hardcoded
                      shape: BoxShape.rectangle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Data: ${NumberFormat.decimalPattern('id_ID').format(tooltipData.value)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataTableSection(Color primaryColor) {
    if (widget.variableCategoryId <= 0 || _chartData.isEmpty) {
      return Container();
    }

    final int flexPeriod = _shouldShowYearColumn ? 3 : 5;
    final int flexValue = _shouldShowYearColumn ? 2 : 3;
    final int flexUnit = _shouldShowYearColumn ? 2 : 3;
    final int flexYear = 2;

    final List<Map<String, String>> tableData = _chartData.asMap().entries.map((
      entry,
    ) {
      final item = entry.value;

      String tablePeriod;

      try {
        final periodStart = DateFormat(
          'd MMM yyyy',
          'id_ID',
        ).format(DateTime.parse(item.periodStart));
        final periodEnd = DateFormat(
          'd MMM yyyy',
          'id_ID',
        ).format(DateTime.parse(item.periodEnd));
        tablePeriod = '$periodStart - $periodEnd';
      } catch (_) {
        tablePeriod = item.periodStart.isNotEmpty && item.periodEnd.isNotEmpty
            ? '${item.periodStart} - ${item.periodEnd}'
            : 'Tahun ${item.year}';
      }

      return {
        'No': (entry.key + 1).toString(),
        'Periode Data': tablePeriod,
        'Nilai': NumberFormat.decimalPattern('id_ID').format(item.value),
        'Satuan': item.unit,
        'Tahun': item.year.toString(),
      };
    }).toList();

    Widget header = Container(
      // MENGGANTI: Warna header tabel hardcoded
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            const Expanded(flex: 1, child: _TableHeaderText('No')),
            Expanded(
              flex: flexPeriod,
              child: const _TableHeaderText('Periode Data'),
            ),
            Expanded(flex: flexValue, child: const _TableHeaderText('Nilai')),
            Expanded(flex: flexUnit, child: const _TableHeaderText('Satuan')),
            if (_shouldShowYearColumn)
              Expanded(flex: flexYear, child: const _TableHeaderText('Tahun')),
          ],
        ),
      ),
    );

    List<Widget> rows = tableData.map((item) {
      return Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Row(
            children: [
              Expanded(flex: 1, child: _TableDataText(item['No']!)),
              Expanded(
                flex: flexPeriod,
                child: _TableDataText(item['Periode Data']!),
              ),
              Expanded(flex: flexValue, child: _TableDataText(item['Nilai']!)),
              Expanded(flex: flexUnit, child: _TableDataText(item['Satuan']!)),
              if (_shouldShowYearColumn)
                Expanded(flex: flexYear, child: _TableDataText(item['Tahun']!)),
            ],
          ),
        ),
      );
    }).toList();

    if (tableData.isEmpty) {
      return Container();
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(children: [header, ...rows]),
    );
  }
}

class _TableHeaderText extends StatelessWidget {
  final String text;
  const _TableHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}

class _TableDataText extends StatelessWidget {
  final String text;
  const _TableDataText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
    );
  }
}

// Fungsi bantu untuk ChartPainter (Tidak berubah)
List<double> getNiceYAxisValues(double rawMaxValue, int numSteps) {
  if (rawMaxValue <= 0) return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

  final double niceRange = rawMaxValue * 1.1;
  final double tempStep = niceRange / numSteps;

  final double exponent = (log(tempStep) / log(10)).floorToDouble();
  final double fraction = tempStep / pow(10, exponent);

  double niceFraction;
  if (fraction <= 1.0) {
    niceFraction = 1.0;
  } else if (fraction <= 2.0) {
    niceFraction = 2.0;
  } else if (fraction <= 5.0) {
    niceFraction = 5.0;
  } else {
    niceFraction = 10.0;
  }

  final double niceStep = niceFraction * pow(10, exponent).toDouble();
  final double niceMax = (niceRange / niceStep).ceilToDouble() * niceStep;

  List<double> values = [];
  for (int i = 0; i <= numSteps; i++) {
    values.add(niceStep * i);
  }

  if (values.last < rawMaxValue) {
    values = getNiceYAxisValues(rawMaxValue * 1.5, numSteps);
  }

  return values;
}

// Custom Painter untuk Chart
class ChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  final double maxValue;
  final String chartType;
  final TooltipData? currentTooltip;
  final Color primaryColor; // BARU: Menerima primaryColor

  ChartPainter({
    required this.data,
    required this.labels,
    required this.maxValue,
    required this.chartType,
    this.currentTooltip,
    required this.primaryColor, // BARU: Menambahkan required this.primaryColor
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    if (chartType == 'Diagram Garis' || chartType == 'Diagram Area') {
      _drawCartesianChart(canvas, size);
    }
  }

  void _drawCartesianChart(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: ui.TextDirection.ltr);
    final axisPaint = Paint()..color = Colors.grey.shade400;

    const numYLines = 5;
    const axisLabelWidth = 35.0;
    final chartWidth = size.width - axisLabelWidth;
    final chartHeight = size.height - 40;

    final chartRect = Rect.fromLTWH(axisLabelWidth, 0, chartWidth, chartHeight);

    final List<double> axisValues = getNiceYAxisValues(
      data.isEmpty ? 1.0 : data.reduce(max),
      numYLines,
    );
    final double niceMax = axisValues.last;

    if (niceMax <= 0 || niceMax.isInfinite || niceMax.isNaN) return;

    for (int i = 0; i < axisValues.length; i++) {
      final value = axisValues[i];
      final yPosition = chartHeight * (1 - (value / niceMax));

      if (yPosition.isNaN) continue;

      textPainter.text = TextSpan(
        text: NumberFormat.compact().format(value),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          axisLabelWidth - textPainter.width - 5,
          yPosition - textPainter.height / 2,
        ),
      );

      if (value > 0) {
        canvas.drawLine(
          Offset(axisLabelWidth, yPosition),
          Offset(size.width, yPosition),
          axisPaint..strokeWidth = 0.5,
        );
      }
    }

    final itemWidth = chartWidth / (data.length > 1 ? data.length - 1 : 1);

    final List<Offset> points = [];
    for (int index = 0; index < data.length; index++) {
      final value = data[index];
      final x = chartRect.left +
          (data.length > 1 ? itemWidth * index : chartWidth / 2);
      final y = chartRect.bottom - (value / niceMax) * chartHeight;
      points.add(Offset(x, y));
    }

    if (points.length > 1) {
      final areaPath = Path()
        ..moveTo(points.first.dx, chartRect.bottom)
        ..lineTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        areaPath.lineTo(points[i].dx, points[i].dy);
      }
      areaPath.lineTo(points.last.dx, chartRect.bottom);
      areaPath.close();

      final areaPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, chartRect.top),
          Offset(0, chartRect.bottom),
          [
            // MENGGANTI: Warna hardcoded dengan primaryColor
            primaryColor.withOpacity(0.3),
            primaryColor.withOpacity(0.0),
          ],
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(areaPath, areaPaint);
    }

    if (points.length > 1) {
      final linePath = Path();
      linePath.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        linePath.lineTo(points[i].dx, points[i].dy);
      }

      canvas.drawPath(
        linePath,
        Paint()
          // MENGGANTI: Warna hardcoded dengan primaryColor
          ..color = primaryColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      final color = (currentTooltip != null && currentTooltip!.index == i)
          ? Colors.blue.shade900
          : primaryColor; // MENGGANTI: Warna hardcoded

      canvas.drawCircle(point, 4.0, Paint()..color = color);

      if (currentTooltip != null && currentTooltip!.index == i) {
        canvas.drawCircle(
          point,
          6.0,
          Paint()..color = Colors.blue.withOpacity(0.3),
        );
      }
    }

    for (int index = 0; index < data.length; index++) {
      final xCenter = chartRect.left +
          (data.length > 1 ? itemWidth * index : chartWidth / 2);

      textPainter.text = TextSpan(
        text: labels[index],
        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
      );
      textPainter.layout();
      canvas.save();
      canvas.translate(xCenter, chartRect.bottom + 10);
      canvas.rotate(pi / 4);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    }

    canvas.drawRect(
      chartRect,
      Paint()
        ..color = Colors.grey.shade300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.chartType != chartType ||
        oldDelegate.labels != labels ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.currentTooltip != currentTooltip ||
        oldDelegate.primaryColor !=
            primaryColor; // BARU: Tambahkan perbandingan warna
  }
}
