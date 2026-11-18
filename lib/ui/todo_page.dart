import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tick/domain/todo.dart';
import 'package:tick/l10n/app_localizations.dart';
import 'package:tick/state/app_controller.dart';
import 'package:tick/ui/theme.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage> {
  final _newTodo = TextEditingController();

  @override
  void dispose() {
    _newTodo.dispose();
    super.dispose();
  }

  Future<void> _addTodo() async {
    final title = _newTodo.text.trim();
    if (title.isEmpty) return;
    _newTodo.clear();
    await _editTodo(initialTitle: title);
  }

  Future<void> _editTodo({TodoItem? todo, String initialTitle = ''}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: TickColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) => _TodoEditor(todo: todo, initialTitle: initialTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final todos = ref.watch(
      appControllerProvider.select((state) => state.todos),
    );
    final open = todos.where((item) => !item.done).toList()
      ..sort(_compareTodoTime);
    final unscheduled = open.where((item) => item.hour == null).toList();
    final scheduled = open.where((item) => item.hour != null).toList();
    final completed = todos.where((item) => item.done).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return Scaffold(
      backgroundColor: TickColors.cream,
      appBar: AppBar(
        backgroundColor: TickColors.cream,
        title: Text(l10n.todoTitle),
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            tooltip: l10n.todoNewTask,
            onPressed: () => _editTodo(),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: [
          PopCard(
            padding: const EdgeInsets.fromLTRB(14, 4, 6, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newTodo,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _addTodo(),
                    decoration: InputDecoration(
                      hintText: l10n.todoTaskHint,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                IconButton.filled(
                  onPressed: _addTodo,
                  style: IconButton.styleFrom(
                    backgroundColor: TickColors.yellow,
                    foregroundColor: TickColors.ink,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  tooltip: l10n.todoAdd,
                ),
              ],
            ),
          ),
          if (todos.isEmpty) ...[
            const SizedBox(height: 32),
            Text(
              l10n.todoNoTasks,
              textAlign: TextAlign.center,
              style: const TextStyle(color: TickColors.muted, fontSize: 15),
            ),
          ] else ...[
            if (scheduled.isNotEmpty) ...[
              _TodoSectionTitle(title: l10n.todoScheduled),
              for (final item in scheduled)
                _TodoRow(
                  todo: item,
                  onToggle: () => ref
                      .read(appControllerProvider.notifier)
                      .toggleTodo(item.id),
                  onEdit: () => _editTodo(todo: item),
                  onDelete: () => ref
                      .read(appControllerProvider.notifier)
                      .deleteTodo(item.id),
                ),
            ],
            if (unscheduled.isNotEmpty) ...[
              _TodoSectionTitle(title: l10n.todoUnscheduled),
              for (final item in unscheduled)
                _TodoRow(
                  todo: item,
                  onToggle: () => ref
                      .read(appControllerProvider.notifier)
                      .toggleTodo(item.id),
                  onEdit: () => _editTodo(todo: item),
                  onDelete: () => ref
                      .read(appControllerProvider.notifier)
                      .deleteTodo(item.id),
                ),
            ],
            if (completed.isNotEmpty) ...[
              _TodoSectionTitle(title: l10n.todoCompleted),
              for (final item in completed)
                _TodoRow(
                  todo: item,
                  onToggle: () => ref
                      .read(appControllerProvider.notifier)
                      .toggleTodo(item.id),
                  onEdit: () => _editTodo(todo: item),
                  onDelete: () => ref
                      .read(appControllerProvider.notifier)
                      .deleteTodo(item.id),
                ),
            ],
          ],
        ],
      ),
    );
  }
}

int _compareTodoTime(TodoItem a, TodoItem b) {
  final left = a.hour;
  final right = b.hour;
  if (left == null && right != null) return 1;
  if (left != null && right == null) return -1;
  if (left != null && right != null && left != right) {
    return left.compareTo(right);
  }
  final priority = b.priority.index.compareTo(a.priority.index);
  if (priority != 0) return priority;
  return a.createdAt.compareTo(b.createdAt);
}

class _TodoSectionTitle extends StatelessWidget {
  const _TodoSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 8),
    child: Text(
      title,
      style: const TextStyle(
        color: TickColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.todo,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final TodoItem todo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = todo.hour == null ? '' : l10n.todoHourLabel(todo.hour!);
    final priority = switch (todo.priority) {
      TodoPriority.low => l10n.todoPriorityLow,
      TodoPriority.normal => l10n.todoPriorityNormal,
      TodoPriority.high => l10n.todoPriorityHigh,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PopCard(
        padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
        child: Row(
          children: [
            Checkbox.adaptive(
              value: todo.done,
              activeColor: TickColors.ink,
              onChanged: (_) => onToggle(),
            ),
            Expanded(
              child: InkWell(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          color: todo.done ? TickColors.muted : TickColors.ink,
                          fontWeight: FontWeight.w700,
                          decoration: todo.done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (time.isNotEmpty ||
                          todo.priority != TodoPriority.normal) ...[
                        const SizedBox(height: 2),
                        Text(
                          [
                            time,
                            if (todo.priority != TodoPriority.normal) priority,
                          ].where((value) => value.isNotEmpty).join(' · '),
                          style: const TextStyle(
                            color: TickColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'edit', child: Text(l10n.todoEdit)),
                PopupMenuItem(value: 'delete', child: Text(l10n.todoDelete)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoEditor extends ConsumerStatefulWidget {
  const _TodoEditor({this.todo, this.initialTitle = ''});

  final TodoItem? todo;
  final String initialTitle;

  @override
  ConsumerState<_TodoEditor> createState() => _TodoEditorState();
}

class _TodoEditorState extends ConsumerState<_TodoEditor> {
  late final TextEditingController _title;
  late bool _hasHour;
  late int _hour;
  late TodoPriority _priority;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(
      text: widget.todo?.title ?? widget.initialTitle,
    );
    _hasHour = widget.todo?.hour != null;
    _hour = widget.todo?.hour ?? DateTime.now().hour;
    _priority = widget.todo?.priority ?? TodoPriority.normal;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final title = _title.text.trim();
    if (title.isEmpty) return;
    ref
        .read(appControllerProvider.notifier)
        .saveTodo(
          id: widget.todo?.id,
          title: title,
          hour: _hasHour ? _hour : null,
          priority: _priority,
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: TickColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _title,
              autofocus: widget.todo == null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _save(),
              decoration: InputDecoration(
                labelText: widget.todo == null
                    ? l10n.todoNewTask
                    : l10n.todoEdit,
                hintText: l10n.todoTaskHint,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.todoHourSection,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: Text(l10n.todoTimeNone),
                  selected: !_hasHour,
                  onSelected: (_) => setState(() => _hasHour = false),
                ),
                ChoiceChip(
                  label: Text(l10n.todoHourChoice),
                  selected: _hasHour,
                  onSelected: (_) => setState(() => _hasHour = true),
                ),
              ],
            ),
            if (_hasHour) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _hour,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.todoHourField),
                items: [
                  for (var hour = 0; hour < 24; hour++)
                    DropdownMenuItem(
                      value: hour,
                      child: Text(l10n.todoHourLabel(hour)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _hour = value);
                },
              ),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.todoPriorityTitle,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _priorityChip(TodoPriority.low, l10n.todoPriorityLow),
                _priorityChip(TodoPriority.normal, l10n.todoPriorityNormal),
                _priorityChip(TodoPriority.high, l10n.todoPriorityHigh),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: FilledButton(onPressed: _save, child: Text(l10n.save)),
            ),
            SizedBox(height: 12 + MediaQuery.paddingOf(context).bottom),
          ],
        ),
      ),
    );
  }

  Widget _priorityChip(TodoPriority priority, String label) => ChoiceChip(
    label: Text(label),
    selected: _priority == priority,
    onSelected: (_) => setState(() => _priority = priority),
  );
}
