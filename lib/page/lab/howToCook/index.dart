import 'package:calorie/network/api.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HowToCookPage extends StatefulWidget {
  const HowToCookPage({super.key});

  @override
  _HowToCookPageState createState() => _HowToCookPageState();
}

class _HowToCookPageState extends State<HowToCookPage> {
  final TextEditingController _dishNameController = TextEditingController();
  bool _isLoading = false;
  String _loadingText = 'AI大师思考中...';
  Map<String, dynamic>? _recipe;
  String? _errorMessage;
  List<String> _searchHistory = [];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
  }

  void _loadSearchHistory() {
    // 这里可以从本地存储加载搜索历史
    // 暂时使用模拟数据
    _searchHistory = ['红烧肉', '宫保鸡丁', '麻婆豆腐', '糖醋里脊'];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // 全屏背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 255, 248, 220),
                  Color.fromARGB(255, 255, 245, 238),
                  Color.fromARGB(255, 255, 240, 245),
                  Color.fromARGB(255, 255, 235, 238),
                  Colors.white,
                ],
              ),
            ),
          ),
          // 主要内容
          SingleChildScrollView(
            child: Column(
              children: [
                // 顶部安全区域
                Container(
                  height: MediaQuery.of(context).padding.top,
                  color: Colors.transparent,
                ),
                // 实际内容
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top > 0 ? 20 : 0,
                    bottom: MediaQuery.of(context).padding.bottom > 0 ? 20 : 0,
                    left: 16,
                    right: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAppBar(),
                      const SizedBox(height: 20),
                      _buildInputSection(),
                      const SizedBox(height: 20),
                      _buildResults(),
                      const SizedBox(height: 20),
                      _buildSearchHistory(),
                    ],
                  ),
                ),
                // 底部安全区域
                Container(
                  height: MediaQuery.of(context).padding.bottom,
                  color: Colors.transparent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '如何做菜',
          style: GoogleFonts.ubuntu(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
      ],
    );
  }

  Widget _buildInputSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🍳', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '输入菜名',
                style: GoogleFonts.ubuntu(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '输入您想学习的菜名，AI大师将为您提供详细的制作教程',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 16),
          // 菜名输入框
          TextField(
            controller: _dishNameController,
            decoration: InputDecoration(
              hintText: '例如：红烧肉、宫保鸡丁、麻婆豆腐...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.orange),
              ),
              suffixIcon: const Icon(Icons.search, color: Colors.grey),
            ),
            onSubmitted: (value) {
              _searchRecipe();
            },
          ),
          const SizedBox(height: 16),
          // 搜索按钮
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _dishNameController.text.trim().isEmpty || _isLoading
                  ? null
                  : _searchRecipe,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(_loadingText),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 8),
                        Text('开始学做菜', style: TextStyle(fontSize: 16)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'AI大师正在为您准备教程...',
              style: GoogleFonts.ubuntu(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadingText,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[300]!),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              '搜索失败',
              style: GoogleFonts.ubuntu(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchRecipe,
              child: const Text('重新搜索'),
            ),
          ],
        ),
      );
    }

    if (_recipe != null) {
      return _buildRecipeCard();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('🍳', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            '等待您的菜名...',
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _buildHintItem('💡', '输入具体菜名效果更好，如"红烧肉"'),
              const SizedBox(height: 8),
              _buildHintItem('🌟', '支持各种菜系：川菜、粤菜、湘菜等'),
              const SizedBox(height: 8),
              _buildHintItem('📝', '包含详细步骤、用料和烹饪技巧'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHintItem(String icon, String text) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildRecipeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 菜谱头部
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.blue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recipe!['name'] ?? '美味佳肴',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '制作教程',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 菜谱内容
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 食材列表
                Text(
                  '所需食材：',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (_recipe!['ingredients'] as List<String>? ?? [])
                      .map((ingredient) => Chip(
                            label: Text(ingredient),
                            backgroundColor: Colors.green[100],
                            labelStyle: const TextStyle(color: Colors.black87),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                // 制作步骤
                Text(
                  '制作步骤：',
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                ...(_recipe!['steps'] as List<Map<String, dynamic>>? ?? [])
                    .asMap()
                    .entries
                    .map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step['description'] ?? '',
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔍', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                '最近搜索',
                style: GoogleFonts.ubuntu(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearHistory,
                child: const Text('清除历史'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _searchHistory
                .take(8)
                .map((item) => ElevatedButton(
                      onPressed: () {
                        _dishNameController.text = item;
                        _searchRecipe();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[100],
                        foregroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 0,
                      ),
                      child: Text(item, style: const TextStyle(fontSize: 12)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  void _searchRecipe() async {
    final dishName = _dishNameController.text.trim();
    if (dishName.isEmpty || _isLoading) return;

    // 添加到历史记录
    if (!_searchHistory.contains(dishName)) {
      setState(() {
        _searchHistory.insert(0, dishName);
        if (_searchHistory.length > 20) {
          _searchHistory = _searchHistory.take(20).toList();
        }
      });
      _saveSearchHistory();
    }

    setState(() {
      _isLoading = true;
      _recipe = null;
      _errorMessage = null;
      _loadingText = 'AI大师思考中...';
    });

    // 模拟AI搜索过程
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loadingText = '正在分析菜谱...';
    });

    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _loadingText = '生成制作步骤...';
    });

    await Future.delayed(const Duration(seconds: 1));

    // 模拟生成结果
    final recipe = {
      'name': dishName,
      'ingredients': [
        '主料：${dishName}所需的主要食材',
        '调料：盐、生抽、老抽、料酒、糖、葱、姜、蒜',
        '配菜：根据${dishName}特点搭配的配菜',
      ],
      'steps': [
        {'description': '准备所有食材，清洗干净，切成适当大小'},
        {'description': '热锅下油，爆香葱姜蒜等调料'},
        {'description': '下主料翻炒至半熟，加入调料调味'},
        {'description': '继续炒制至熟透，注意火候控制'},
        {'description': '最后调味，装盘即可享用'},
      ],
    };

    setState(() {
      _isLoading = false;
      _recipe = recipe;
    });
  }

  void _clearHistory() {
    setState(() {
      _searchHistory.clear();
    });
    _saveSearchHistory();
  }

  void _saveSearchHistory() {
    // 这里可以保存到本地存储
    // 暂时只是更新状态
  }

  @override
  void dispose() {
    _dishNameController.dispose();
    super.dispose();
  }
}
