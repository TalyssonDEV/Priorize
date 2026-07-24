import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Assumindo a estrutura padrão de pacotes do Flutter, onde os modelos estão em lib/model/
import 'package:priorize/model/categoria_model.dart'; // Correção crítica: importando o modelo
import 'package:priorize/viewmodel/tarefa_viewmodel.dart';
import 'package:priorize/viewmodel/categoria_viewmodel.dart';
import 'package:priorize/view/screens/shared_rooms_screen.dart';
import 'package:priorize/view/screens/websocket_teste_screen.dart';
import 'package:priorize/view/widgets/adicionar_tarefa_dialog.dart';
import 'package:priorize/view/widgets/filtro_prioridade_sheet.dart';
import 'package:priorize/view/widgets/gerenciar_categorias_sheet.dart';
import '../widgets/tarefa_card.dart';
// Cores baseadas na imagem
const Color primaryPurple = Color(0xFF673AB7);
const Color secondaryPurple = Color(0xFF9575CD);
const Color textPrimary = Colors.black;
const Color textSecondary = Colors.grey;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF7F7FB),
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho
            _buildCustomHeader(context),

            // Conteúdo
            _buildTitleAndSubtitle(),
            _buildProgressoGeralCard(),
            _buildStatsCards(),
            _buildCategoryTags(),
            Expanded(child: _buildListaTarefasContent()),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddTask(context),
        backgroundColor: primaryPurple,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });

                if (index == 1) {
                  _navigateToSharedRooms(context);
                } else if (index == 2) {
                  _navigateToWebSocketTest(context);
                }
              },
              elevation: 0,
              backgroundColor: Colors.white,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: primaryPurple,
              unselectedItemColor: textSecondary,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.task_alt_rounded),
                  label: 'Tarefas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.group_rounded),
                  label: 'Salas',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.swap_horiz_rounded),
                  label: 'Transferências',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Cabeçalho customizado
  Widget _buildCustomHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      decoration: const BoxDecoration(
        color: primaryPurple,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'P',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Priorize',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Olá Talysson',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 30,
              ),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.deepOrangeAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Título e subtítulo
  Widget _buildTitleAndSubtitle() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        children: [
          Text(
            'Tarefas',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Gerencie suas tarefas',
            style: TextStyle(
              fontSize: 15,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  // Cartão de progresso geral
  Widget _buildProgressoGeralCard() {
    return Consumer<TarefaViewModel>(
      builder: (context, viewModel, _) {
        final progresso = viewModel.progressoTarefas;
        final concluidas = viewModel.tarefasConcluidas;
        final total = viewModel.totalTarefas;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progresso geral',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$concluidas/$total concluídas',
                      style: const TextStyle(fontSize: 14, color: textSecondary),
                    ),
                    Text(
                      '${(progresso * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 10,
                    backgroundColor: Colors.grey[200],
                    color: primaryPurple,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Cartões de estatísticas (Pendentes, Categorias, Prioridade)
  Widget _buildStatsCards() {
    return Consumer2<TarefaViewModel, CategoriaViewModel>(
      builder: (context, tarefaVM, categoriaVM, _) {
        final pendentesCount = tarefaVM.tarefasNaoConcuidas;
        final categoriasCount = categoriaVM.categorias.length;
        final altaPrioridadeCount = tarefaVM.contarTarefasPorPrioridade('Alta');

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: _EstatisticaCard(
                  valor: pendentesCount.toString(),
                  titulo: 'Pendentes',
                  cor: Colors.redAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _navigateToManageCategories(context),
                  child: _EstatisticaCard(
                    valor: categoriasCount.toString(),
                    titulo: 'Categorias',
                    cor: primaryPurple,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => _showFilterPrioritySheet(context),
                  child: _EstatisticaCard(
                    valor: altaPrioridadeCount.toString(),
                    titulo: 'Alta',
                    cor: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Chips de filtro por categoria como tags
  Widget _buildCategoryTags() {
    return Consumer2<CategoriaViewModel, TarefaViewModel>(
      builder: (context, categoriaVM, tarefaVM, _) {
        if (categoriaVM.categorias.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categoriaVM.categorias.length + 1,
            itemBuilder: (context, index) {
              final isTodas = index == 0;
              final categoria = isTodas ? null : categoriaVM.categorias[index - 1];
              final label = isTodas ? 'Todas' : categoria!.tipo;
              final isSelected = isTodas
                  ? tarefaVM.categoriaIdSelecionada == null
                  : tarefaVM.categoriaIdSelecionada == categoria!.id;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (_) {
                    if (isTodas) {
                      tarefaVM.limparFiltroCategoria();
                    } else {
                      tarefaVM.obterPorCategoria(categoria!.id);
                    }
                  },
                  backgroundColor: Colors.grey[100],
                  selectedColor: primaryPurple,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : textPrimary,
                    fontWeight: FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? primaryPurple : Colors.grey[200]!,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Conteúdo da lista de tarefas, lidando com estados
  Widget _buildListaTarefasContent() {
    return Consumer<TarefaViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.estaCarregando) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.mensagemErro != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  viewModel.mensagemErro!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    viewModel.limparErro();
                    viewModel.carregarTarefas();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
                ),
              ],
            ),
          );
        }

        if (viewModel.tarefas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text(
                  'Nenhuma tarefa',
                  style: TextStyle(
                    fontSize: 18,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Adicione uma nova tarefa para começar',
                  style: TextStyle(fontSize: 14, color: textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: viewModel.tarefas.length,
          itemBuilder: (context, index) {
            final tarefa = viewModel.tarefas[index];
            return TarefaCard(tarefa: tarefa);
          },
        );
      },
    );
  }

  // Navegação para as novas telas e flows
  void _navigateToAddTask(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AdicionarTarefaDialog(),
    );
  }

  void _navigateToManageCategories(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const GerenciarCategoriasSheet(),
    );
  }

  void _showFilterPrioritySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const FiltroPrioridadeSheet(),
    );
  }

  void _navigateToSharedRooms(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SharedRoomsScreen()));
  }

  void _navigateToWebSocketTest(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const WebSocketTesteScreen()));
  }
}

// Widget auxiliar para os cartões de estatísticas
class _EstatisticaCard extends StatelessWidget {
  final String valor;
  final String titulo;
  final Color cor;

  const _EstatisticaCard({
    required this.valor,
    required this.titulo,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Text(
              valor,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====== TELAS ADICIONAIS CONFORME A IMAGEM (para fins de demonstração neste arquivo) ======

// TELA 2 & 3: Nova tarefa e Busca de Categoria
class AddTaskFlowScreen extends StatefulWidget {
  const AddTaskFlowScreen({super.key});

  @override
  State<AddTaskFlowScreen> createState() => _AddTaskFlowScreenState();
}

class _AddTaskFlowScreenState extends State<AddTaskFlowScreen> {
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  String? _selectedCategoryId;
  int _selectedPriority = 1; // 1 = Baixa, 2 = Média, 3 = Alta

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova tarefa'),
        backgroundColor: primaryPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Título', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _tituloController,
              decoration: const InputDecoration(hintText: 'Ex: Passear com o Dog', border: UnderlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text('Descrição (opcional)', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _descricaoController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Descreva os detalhes...', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text('Categoria', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildCategorySelector(),
            const SizedBox(height: 20),
            const Text('Prioridade', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildPrioritySelector(),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar', style: TextStyle(color: primaryPurple)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _adicionarTarefa,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
                    child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<CategoriaViewModel>(
      builder: (context, categoriaVM, _) {
        String label = 'Selecione a categoria';
        IconData icon = Icons.keyboard_arrow_down;
        if (_selectedCategoryId != null) {
          final cat = categoriaVM.categorias.firstWhere((c) => c.id == _selectedCategoryId);
          label = cat.tipo;
          icon = Icons.category_outlined; // Assuma que temos o ícone correto
        }

        return InkWell(
          onTap: () => _showCategorySearchSheet(context, categoriaVM),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: textSecondary),
                    const SizedBox(width: 10),
                    Text(label, style: const TextStyle(color: textPrimary)),
                  ],
                ),
                const Icon(Icons.arrow_drop_down, color: textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _PriorityButton(
          title: 'Baixa',
          priorityValue: 1,
          selectedPriority: _selectedPriority,
          color: Colors.green,
          onTap: () => setState(() => _selectedPriority = 1),
        ),
        _PriorityButton(
          title: 'Média',
          priorityValue: 2,
          selectedPriority: _selectedPriority,
          color: Colors.orange,
          onTap: () => setState(() => _selectedPriority = 2),
        ),
        _PriorityButton(
          title: 'Alta',
          priorityValue: 3,
          selectedPriority: _selectedPriority,
          color: Colors.red,
          onTap: () => setState(() => _selectedPriority = 3),
        ),
      ],
    );
  }

  void _showCategorySearchSheet(BuildContext context, CategoriaViewModel categoriaVM) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return _CategorySearchSheet(
          categorias: categoriaVM.categorias,
          selectedCategoryId: _selectedCategoryId,
          onCategorySelected: (id) {
            setState(() => _selectedCategoryId = id);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _adicionarTarefa() {
    // Implemente a lógica real usando TarefaViewModel.adicionarTarefa
    // Correção Ln 688 Col 11: Variável viewModel não utilizada removida.
    // ...
    Navigator.pop(context);
  }
}

// Widget auxiliar para os botões de prioridade (Alta, Média, Baixa)
class _PriorityButton extends StatelessWidget {
  final String title;
  final int priorityValue;
  final int selectedPriority;
  final Color color;
  final VoidCallback onTap;

  const _PriorityButton({
    required this.title,
    required this.priorityValue,
    required this.selectedPriority,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = priorityValue == selectedPriority;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // Correção de deprecation: withOpacity -> withValues
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.arrow_downward, color: color, size: 16), // Ícone genérico de prioridade
            const SizedBox(width: 5),
            Text(title, style: TextStyle(color: isSelected ? color : textPrimary)),
          ],
        ),
      ),
    );
  }
}

// TELA 3: Sheet de Busca de Categoria
class _CategorySearchSheet extends StatefulWidget {
  final List<CategoriaModel> categorias;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;

  const _CategorySearchSheet({
    required this.categorias,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  State<_CategorySearchSheet> createState() => _CategorySearchSheetState();
}

class _CategorySearchSheetState extends State<_CategorySearchSheet> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredCategories = widget.categorias
        .where((cat) => cat.tipo.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Buscar categoria...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 20),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final cat = filteredCategories[index];
                return ListTile(
                  title: Text(cat.tipo),
                  trailing: Checkbox(
                    value: cat.id == widget.selectedCategoryId,
                    onChanged: (value) => widget.onCategorySelected(cat.id),
                    activeColor: primaryPurple,
                  ),
                  onTap: () => widget.onCategorySelected(cat.id),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: primaryPurple, minimumSize: const Size(double.infinity, 50)),
            child: const Text('Selecionar Categoria', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, color: primaryPurple),
            label: const Text('Nova categoria', style: TextStyle(color: primaryPurple)),
          ),
        ],
      ),
    );
  }
}

// TELA 4: Salas compartilhadas
class SharedRoomsFlowScreen extends StatelessWidget {
  const SharedRoomsFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salas compartilhadas'),
        backgroundColor: primaryPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IP do servidor (Spring Boot)', style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(
              decoration: InputDecoration(hintText: '10.50.195.125', border: UnderlineInputBorder()),
            ),
            const SizedBox(height: 20),
            const Text('Seu nome', style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(
              decoration: InputDecoration(hintText: 'PC-JOAO', border: UnderlineInputBorder()),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: primaryPurple, minimumSize: const Size(double.infinity, 50)),
              child: const Text('+ Criar sala', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Código para entrar', style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.qr_code_scanner, color: textSecondary)),
              ],
            ),
            const TextField(
              decoration: InputDecoration(hintText: 'Digite o código da sala', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 30),
            const Text('Minhas salas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildRoomCard(),
          ],
        ),
          ),
    );
  }

  Widget _buildRoomCard() {
    return const Card(
      child: ListTile(
        leading: Icon(Icons.folder_shared, color: primaryPurple, size: 30),
        title: Text('Sala de Projetos'),
        subtitle: Text('3 membros • 192.168.0.15'),
        trailing: Icon(Icons.arrow_forward_ios, color: textSecondary, size: 16),
      ),
    );
  }
}

// TELA 5: Teste WebSocket
class WebSocketTestFlowScreen extends StatefulWidget {
  const WebSocketTestFlowScreen({super.key});

  @override
  State<WebSocketTestFlowScreen> createState() => _WebSocketTestFlowScreenState();
}

class _WebSocketTestFlowScreenState extends State<WebSocketTestFlowScreen> {
  bool _isConnected = true;
  final _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste WebSocket'),
        backgroundColor: primaryPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('IP do servidor', style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(
              decoration: InputDecoration(hintText: '10.50.195.125', border: UnderlineInputBorder()),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected ? null : () => setState(() => _isConnected = true),
                    style: ElevatedButton.styleFrom(backgroundColor: primaryPurple),
                    child: const Text('Conectar', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: OutlinedButton(
                    onPressed: !_isConnected ? null : () => setState(() => _isConnected = false),
                    child: const Text('Desconectar', style: TextStyle(color: primaryPurple)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(Icons.circle, color: _isConnected ? Colors.green : Colors.red, size: 12),
                const SizedBox(width: 8),
                Text('Status: ${_isConnected ? 'Conectado' : 'Desconectado'}', style: const TextStyle(color: textSecondary)),
              ],
            ),
            const SizedBox(height: 30),
            const Text('Mensagem', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(hintText: 'Digite sua mensagem...', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.send, color: Colors.white),
              style: ElevatedButton.styleFrom(backgroundColor: primaryPurple, minimumSize: const Size(double.infinity, 50)),
              label: const Text('Enviar mensagem', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 30),
            const Text('Mensagens recebidas:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildReceivedMessages(),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedMessages() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                // Correção de deprecation: withOpacity -> withValues
                color: primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Servidor', style: TextStyle(fontWeight: FontWeight.bold, color: primaryPurple)),
                SizedBox(height: 5),
                Text('Conexão estabelecida com sucesso!', style: TextStyle(color: textPrimary)),
                SizedBox(height: 5),
                Text('10:30:45', style: TextStyle(color: textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// TELA 6: Filtrar por prioridade (na imagem, parece ser uma tela cheia ou um sheet muito alto)
class FilterPriorityFlowScreen extends StatelessWidget {
  const FilterPriorityFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filtrar por prioridade', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
          _buildFilterOption(icon: Icons.list_alt, title: 'Todas', subtitle: 'Mostrar todas as prioridades', isSelected: true),
          _buildFilterOption(icon: Icons.arrow_upward, title: 'Alta', subtitle: 'Tarefas de alta prioridade', color: Colors.red),
          _buildFilterOption(icon: Icons.minimize, title: 'Média', subtitle: 'Tarefas de média prioridade', color: Colors.orange),
          _buildFilterOption(icon: Icons.arrow_downward, title: 'Baixa', subtitle: 'Tarefas de baixa prioridade', color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildFilterOption({required IconData icon, required String title, required String subtitle, Color? color, bool isSelected = false}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color ?? textSecondary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(color: textSecondary)),
      trailing: isSelected ? const Icon(Icons.check_circle, color: primaryPurple) : const Icon(Icons.circle_outlined, color: textSecondary),
      onTap: () {},
    );
  }
}

// TELA 7: Gerenciar categorias
class ManageCategoriesFlowScreen extends StatelessWidget {
  const ManageCategoriesFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar categorias'),
        backgroundColor: primaryPurple,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add, color: Colors.white)),
        ],
      ),
      body: Consumer<CategoriaViewModel>(
        builder: (context, categoriaVM, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: categoriaVM.categorias.length,
            itemBuilder: (context, index) {
              final cat = categoriaVM.categorias[index];
              return _buildCategoryManageCard(context, cat);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryManageCard(BuildContext context, CategoriaModel cat) {
    final IconData priorityIcon;
    final Color priorityColor;
    final String prioridadeLabel;

    switch (cat.nivelPrioridade) {
      case 'Alta':
        priorityIcon = Icons.arrow_upward;
        priorityColor = Colors.red;
        prioridadeLabel = 'Alta prioridade';
        break;
      case 'Média':
        priorityIcon = Icons.remove;
        priorityColor = Colors.orange;
        prioridadeLabel = 'Média prioridade';
        break;
      default:
        priorityIcon = Icons.arrow_downward;
        priorityColor = Colors.green;
        prioridadeLabel = 'Baixa prioridade';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(priorityIcon, color: priorityColor, size: 28),
        title: Text(cat.tipo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${cat.id.length} tarefa${cat.id.length == 1 ? '' : 's'}\n$prioridadeLabel', style: const TextStyle(color: textSecondary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.edit, color: textSecondary)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.delete, color: textSecondary)),
          ],
        ),
      ),
    );
  }
}