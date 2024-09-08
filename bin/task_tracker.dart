import 'dart:io';
import 'dart:convert';

const String dbName = "db.json";

void main(List<String> arguments) {
  createDatabase();

  while (true) {
    stdout.write("task-cli ");
    String userInput = stdin.readLineSync()!;

    while (userInput.trim() == '') {
      print("\nInvalid command\n");
      stdout.write("task-cli ");
      userInput = stdin.readLineSync()!;
    }

    if (userInput == 'exit') {
      exit(0);
    }

    final RegExp pattern = RegExp('\\s(?=(?:[^\'"]|\'[^\']*\'|"[^"]*")*\$)');
    final List<String> splittedUserInput = userInput.split(pattern);
    final String cmd = splittedUserInput[0];

    switch (cmd) {
      case 'add':
        final String taskDescription = splittedUserInput[1];

        if (splittedUserInput.length == 1) {
          print("\nProvide a task description\n");
        } else if (!taskDescription.contains('"')) {
          print("\nInvalid task description format\n");
        } else {
          createTask(taskDescription.replaceAll('"', ''));
          print("\nNew task added\n");
        }

        break;

      case 'delete':
        try {
          final int taskId = int.parse(splittedUserInput[1]);
          deleteTask(taskId);
          print("\nTask deleted\n");
        } catch (e) {
          print("\nTask ID must be a valid number\n");
        }

        break;

      case 'list':
        if (!jsonHasData()) {
          print("\nNo tasks yet\n");
        } else {
          if (splittedUserInput.length == 1) {
            final List<Map<String, dynamic>> allDb =
                List.from(jsonDecode(readDatabase()));

            if (allDb.isEmpty) {
              print("No tasks yet");
            } else {
              print("\n=================\n");
              print("Listing all tasks");
              print("\n=================\n");
              for (final elem in allDb) {
                print("id: ${elem["id"]}");
                print("description: ${elem["description"]}");
                print("status: ${elem["status"]}");
                print("createdAt: ${elem["createdAt"]}");
                print("updatedAt: ${elem["updatedAt"]}");
                print("=================\n");
              }
            }
          } else {
            final String filter = splittedUserInput[1];
            final List<Map<String, dynamic>> filteredData =
                listByStatus(filter);

            if (filteredData.isEmpty) {
              print("\nNo $filter tasks\n");
            } else {
              print("\n=================\n");
              print("Listing all $filter tasks");
              print("\n=================\n");
              for (final elem in filteredData) {
                print("id: ${elem["id"]}");
                print("description: ${elem["description"]}");
                print("status: ${elem["status"]}");
                print("createdAt: ${elem["createdAt"]}");
                print("updatedAt: ${elem["updatedAt"]}");
                print("=================\n");
              }
            }
          }
        }

        break;

      case 'mark-done':
        try {
          final int taskId = int.parse(splittedUserInput[1]);
          updateTask(taskId, 'done', null);
          print("\nTask marked as done\n");
        } catch (e) {
          print("\nTask ID must be a valid number\n");
        }

        break;

      case 'mark-in-progress':
        try {
          final int taskId = int.parse(splittedUserInput[1]);
          updateTask(taskId, 'in-progress', null);
          print("\nTask marked as in-progress\n");
        } catch (e) {
          print("\nTask ID must be a valid number\n");
        }

        break;

      case 'update':
        if (splittedUserInput.isNotEmpty && splittedUserInput.length < 3) {
          print("\nNo task ID provided or new description\n");
        } else {
          try {
            final int taskId = int.parse(splittedUserInput[1]);
            final String newDescription = splittedUserInput.last;

            if (!newDescription.contains('"')) {
              print("\nInvalid task description format\n");
            } else {
              updateTask(taskId, null, newDescription.replaceAll('"', ''));
              print("\nTask updated\n");
            }
          } catch (e) {
            print("\nTask ID must be a valid number\n");
          }
        }

        break;

      default:
        print("\nInvalid command\n");
    }
  }
}

void createDatabase() {
  final File jsonDbFile = File(dbName);

  if (!jsonDbFile.existsSync()) {
    jsonDbFile.createSync();
  }
}

bool jsonHasData() {
  final File jsonDbFile = File(dbName);
  final String jsonData = jsonDbFile.readAsStringSync();

  return jsonData.trim() != '';
}

String readDatabase() {
  final File jsonDbFile = File(dbName);

  return jsonDbFile.readAsStringSync();
}

void writeData(List<Map<String, dynamic>> data) {
  final File jsonDbFile = File(dbName);
  final String newJsonDb = jsonEncode(data);

  jsonDbFile.writeAsStringSync(newJsonDb);
}

void createTask(String taskDescription) {
  int newId = 1;
  List<Map<String, dynamic>> jsonDb = [];

  if (jsonHasData()) {
    jsonDb = List.from(jsonDecode(readDatabase()));
    newId = jsonDb.last["id"] + 1;
  }

  final Map<String, dynamic> newTask = {
    "id": newId,
    "description": taskDescription,
    "status": "todo",
    "createdAt": DateTime.now().toIso8601String(),
    "updatedAt": DateTime.now().toIso8601String()
  };

  jsonDb.add(newTask);

  writeData(jsonDb);
}

void deleteTask(int taskId) {
  List<Map<String, dynamic>> jsonDb = List.from(jsonDecode(readDatabase()));

  List<Map<String, dynamic>> newJsonDb =
      jsonDb.where((task) => task['id'] != taskId).toList();

  writeData(newJsonDb);
}

void updateTask(int taskId, String? status, String? description) {
  List<Map<String, dynamic>> jsonDb = List.from(jsonDecode(readDatabase()));

  List<Map<String, dynamic>> newJsonDb = [];
      
  for (final task in jsonDb) {
    if (task['id'] == taskId) {
      if (status != null) {
        task['status'] = status;
      } else if (description != null) {
        task['description'] = description;
      }
      task['updatedAt'] = DateTime.now().toIso8601String();
    }

    newJsonDb.add(task);
  }

  writeData(newJsonDb);
}

List<Map<String, dynamic>> listByStatus(String filter) {
  final List<Map<String, dynamic>> jsonDb =
      List.from(jsonDecode(readDatabase()));

  return jsonDb.where((task) => task['status'] == filter).toList();
}
