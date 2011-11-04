class TableController < UITableViewController
  def viewDidLoad
    @data = {}
    @data['Trappist'] = [
      'Chimay',
      'Orval',
      'Rochefort',
      'Westmalle',
      'Westvleteren',
      'Achel'
    ]
    @data['Abbaye'] = [
      "Abbaye de Saint-Martin",
      "Abdij Dendermonde",
      "Abdij St.-Pieter",
      "Affligem",
      "Baudeloo",
      "Bornem",
      "Bonne-Espérance",
      "Cambron",
      "Ename",
      "Floreffe",
      "Grimbergen",
      "Keizersberg",
      "Leffe",
      "Maredsous",
      "Postel",
      "St.-Feuillien",
      "Steenbrugge",
      "Tongerlo",
      "Val-Dieu"
    ]
    view.dataSource = view.delegate = self
  end

  def numberOfSectionsInTableView(tableView)
    @data.keys.size
  end

  def tableView(tableView, numberOfRowsInSection:section)
    sectionKey = @data.keys[section]
    @data[sectionKey].size
  end

  def tableView(tableView, titleForHeaderInSection:section)
    @data.keys[section]
  end

  CELLID = 'CellIdentifier'
  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    sectionKey = @data.keys[indexPath.section]
    row = @data[sectionKey][indexPath.row]

    cell = tableView.dequeueReusableCellWithIdentifier(CELLID) || UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier:CELLID)
    cell.textLabel.text = row
    cell
  end
end

class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.applicationFrame)
    window.rootViewController = TableController.alloc.initWithStyle(UITableViewStylePlain)
    window.rootViewController.wantsFullScreenLayout = true
    window.makeKeyAndVisible
    return true
  end
end
