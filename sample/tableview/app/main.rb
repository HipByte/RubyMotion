class TableController
  def initialize
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

    tvrect = window.bounds
    tv = UITableView.alloc.initWithFrame(tvrect, style:UITableViewStylePlain)
    tv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth
    tv.dataSource = tv.delegate = TableController.new
    window.addSubview(tv)

    window.makeKeyAndVisible
  end
end
