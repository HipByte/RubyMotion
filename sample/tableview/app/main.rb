class CatTableController
  def initialize
    @cats = {}
    @cats['Tabby'] = ['Cerise', 'Kiwi']
    @cats['Awesome'] = ['Nyan']
  end

  def numberOfSectionsInTableView(tableView)
    @cats.keys.size
  end

  def tableView(tableView, numberOfRowsInSection:section)
    sectionKey = @cats.keys[section]
    @cats[sectionKey].size
  end

  def tableView(tableView, titleForHeaderInSection:section)
    @cats.keys[section]
  end

  CELLID = 'CellIdentifier'
  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    sectionKey = @cats.keys[indexPath.section]
    cat = @cats[sectionKey][indexPath.row]

    cell = tableView.dequeueReusableCellWithIdentifier(CELLID) || UITableViewCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier:CELLID)
    cell.textLabel.text = cat
    cell
  end
end

class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.applicationFrame)

    tvrect = window.bounds
    tv = UITableView.alloc.initWithFrame(tvrect, style:UITableViewStylePlain)
    tv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth
    tv.dataSource = tv.delegate = CatTableController.new
    window.addSubview(tv)

    window.makeKeyAndVisible
  end
end
