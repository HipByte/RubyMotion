class Tweet
  def initialize(dict)
    @author = NSString.alloc.initWithString(dict['from_user_name']) # workaround gc bug
    @message = NSString.alloc.initWithString(dict['text']) # workaround gc bug
    @profile_image_url = NSString.alloc.initWithString(dict['profile_image_url']) # workaround gc bug
    @profile_image = nil
  end

  def load_profile_picture(table_view, row)
    Dispatch::Queue.concurrent.async do
      profile_image_data = NSData.alloc.initWithContentsOfURL(NSURL.URLWithString(@profile_image_url))
      if profile_image_data
        Dispatch::Queue.main.sync do
          @profile_image = UIImage.alloc.initWithData(profile_image_data)
          index_path = NSIndexPath.indexPathForRow(row, inSection:0)
          table_view.reloadRowsAtIndexPaths([index_path], withRowAnimation:false)
        end
      end
    end
  end

  def height(table_view)
    @height ||= begin
      constrain = CGSize.new(table_view.frame.size.width - 57, 1000)
      size = @message.sizeWithFont(UIFont.systemFontOfSize(14), constrainedToSize:constrain)
      [57, size.height + 8].max
    end
  end

  def prepareCell(cell)
    cell.imageView.image = @profile_image
    cell.textLabel.text = @message
  end
end

class TweetCell < UITableViewCell
  def initWithStyle(style, reuseIdentifier:cellid)
    if super
      self.textLabel.numberOfLines = 0
      self.textLabel.font = UIFont.systemFontOfSize(14)
    end
    self
  end

  def layoutSubviews
    super
    self.imageView.frame = CGRectMake(2, 2, 49, 49)
    label_size = self.frame.size
    self.textLabel.frame = CGRectMake(57, 0, label_size.width - 59, label_size.height)
  end
end

class TweetsController < UITableViewController
  def viewDidLoad
    @tweets = []
    searchBar = UISearchBar.alloc.initWithFrame(CGRectMake(0, 0, self.tableView.frame.size.width, 0))
    searchBar.delegate = self;
    searchBar.showsCancelButton = true;
    searchBar.sizeToFit
    view.tableHeaderView = searchBar
    view.dataSource = view.delegate = self

    searchBar.text = 'Hello'
    searchBarSearchButtonClicked(searchBar)
  end

  def searchBarSearchButtonClicked(searchBar)
    query = searchBar.text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
    url = "http://search.twitter.com/search.json?q=#{query}"

    @tweets.clear
    Dispatch::Queue.concurrent.async do 
      error_ptr = Pointer.new(:object)
      data = NSData.alloc.initWithContentsOfURL(NSURL.URLWithString(url), options:NSDataReadingUncached, error:error_ptr)
      unless data
        presentError error_ptr[0]
        return
      end
      json = NSJSONSerialization.JSONObjectWithData(data, options:0, error:error_ptr)
      unless json
        presentError error_ptr[0]
        return
      end

      new_tweets = []
      json['results'].each do |dict|
        new_tweets << Tweet.new(dict)
      end

      Dispatch::Queue.main.sync { load_tweets(new_tweets) }
    end

    searchBar.resignFirstResponder
  end

  def searchBarCancelButtonClicked(searchBar)
    searchBar.resignFirstResponder
  end

  def load_tweets(tweets)
    @tweets = tweets
    @tweets.each_with_index do |tweet, idx|
      tweet.load_profile_picture(self.view, idx)
    end
    view.reloadData
  end
 
  def presentError(error)
    # TODO
    $stderr.puts error.description
  end
 
  def tableView(tableView, numberOfRowsInSection:section)
    @tweets.size
  end

  def tableView(tableView, heightForRowAtIndexPath:indexPath)
    @tweets[indexPath.row].height(tableView)
  end

  CellID = 'CellIdentifier'
  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    cell = tableView.dequeueReusableCellWithIdentifier(CellID) || TweetCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier:CellID)

    tweet = @tweets[indexPath.row]
    tweet.prepareCell(cell)
    return cell
  end
end

class AppDelegate
  def application(application, didFinishLaunchingWithOptions:launchOptions)
    window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.applicationFrame)
    window.rootViewController = TweetsController.alloc.initWithStyle(UITableViewStylePlain)
    window.rootViewController.wantsFullScreenLayout = true
    window.makeKeyAndVisible
    return true
  end
end
