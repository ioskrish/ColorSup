//
//  MagicTableViewController.swift
//  ColorSup
//
//  Created by Krishna Panchal on 13/11/23.
//

import UIKit

class MagicTableViewController: UITableViewController {


    // MARK: Properties

    var deleteAllButton: UIBarButtonItem!

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if CommandLine.arguments.contains("--colorSupScreenshots") {
            // We are in testing mode, make arrangements if needed
            UIView.setAnimationsEnabled(false)
        }

        navigationController?.navigationBar.prefersLargeTitles = true
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.title = "Random History"

        deleteAllButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self,
                                          action: #selector(deleteAll))
        deleteAllButton.tintColor = .red
    }


    // MARK: Helpers

    @objc func deleteAll() {
        let alert = createAlert(alertReasonParam: .deleteHistory, okMessage: "No")
        let deleteAction = UIAlertAction(title: "Yes", style: .destructive) { [self] _ in
            var currentArray: [String] = readFromDocs(
                withFileName: Const.UserDef.randomHistoryFilename) ?? []
            currentArray = []
            saveToDocs(text: currentArray.joined(separator: ","),
                       withFileName: Const.UserDef.randomHistoryFilename)
            tableView.reloadData()
            setEditing(false, animated: true)
        }
        alert.addAction(deleteAction)
        present(alert, animated: true)
    }

    func getArray() -> [String]? {
        var myArray = readFromDocs(
            withFileName: Const.UserDef.randomHistoryFilename)
        myArray = myArray?.uniqued()
        return myArray?.reversed() // ?.sorted { $0 < $1 }
    }


    // MARK: TableView

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.navigationItem.rightBarButtonItems = editing ? [editButtonItem, deleteAllButton]
        : [editButtonItem]
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let rootViewController = self.navigationController!.viewControllers.first
        as! MakerViewController
        let theHexValue: String = getArray()![indexPath.row]
        rootViewController.updateColor(hexStringParam: theHexValue)

        self.navigationController!.popToRootViewController(animated: true)
    }


    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: Const.StoryboardIDIB.magicCell) as! MagicCell
        cell.hexLabel.text = "HEX: \(getArray()![indexPath.row])"
        cell.colorView.backgroundColor = uiColorFrom(hex: getArray()![indexPath.row])
        cell.colorView.layer.cornerRadius = 6
        return cell
    }


    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }


    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return getArray()?.count ?? 0
    }


    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {

        return Const.AppInfo.historyHeader
    }


    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt
                            indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(
            style: .destructive, title: "Delete",
            handler: { [self] (_, _, success: (Bool) -> Void) in
                let hexKeyItem: String = getArray()![indexPath.row]
                var currentArray: [String] = readFromDocs(
                    withFileName: Const.UserDef.randomHistoryFilename) ?? []
                currentArray = currentArray.filter { $0 != hexKeyItem }
                saveToDocs(text: currentArray.joined(separator: ","),
                           withFileName: Const.UserDef.randomHistoryFilename)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                success(true)
            })
        deleteAction.backgroundColor = .red
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }

}
