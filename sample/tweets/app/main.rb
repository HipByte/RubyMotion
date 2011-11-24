class Tweet  
  def initialize(dict)
    @author = NSString.alloc.initWithString(dict['from_user_name']) # workaround gc bug
    @message = NSString.alloc.initWithString(dict['text']) # workaround gc bug
    @profile_image_url = NSString.alloc.initWithString(dict['profile_image_url']) # workaround gc bug
    @profile_image = nil
  end
 
  attr_reader :author, :message, :profile_image_url
  attr_accessor :profile_image
end

class TweetCell < UITableViewCell
  CellID = 'CellIdentifier'
  MessageFontSize = 14

  def self.cellForTweet(tweet, inTableView:tableView)
    cell = tableView.dequeueReusableCellWithIdentifier(TweetCell::CellID) || TweetCell.alloc.initWithStyle(UITableViewCellStyleDefault, reuseIdentifier:CellID)
    cell.fillWithTweet(tweet, inTableView:tableView)
    cell
  end
 
  def initWithStyle(style, reuseIdentifier:cellid)
    if super
      self.textLabel.numberOfLines = 0
      self.textLabel.font = UIFont.systemFontOfSize(MessageFontSize)
    end
    self
  end
 
  def fillWithTweet(tweet, inTableView:tableView)
    self.textLabel.text = tweet.message
    
    unless tweet.profile_image
      self.imageView.image = nil
      Dispatch::Queue.concurrent.async do
        profile_image_data = NSData.alloc.initWithContentsOfURL(NSURL.URLWithString(tweet.profile_image_url))
        if profile_image_data
          tweet.profile_image = UIImage.alloc.initWithData(profile_image_data)
          Dispatch::Queue.main.sync do
            self.imageView.image = tweet.profile_image
            tableView.delegate.reloadRowForTweet(tweet)
          end
        end
      end
    else
      self.imageView.image = tweet.profile_image
    end
  end

  def self.heightForTweet(tweet, width)
    constrain = CGSize.new(width - 57, 1000)
    size = tweet.message.sizeWithFont(UIFont.systemFontOfSize(MessageFontSize), constrainedToSize:constrain)
    [57, size.height + 8].max
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
    TweetCell.heightForTweet(@tweets[indexPath.row], tableView.frame.size.width)
  end

  def tableView(tableView, cellForRowAtIndexPath:indexPath)
    tweet = @tweets[indexPath.row]
    TweetCell.cellForTweet(tweet, inTableView:tableView)
  end
  
  def reloadRowForTweet(tweet)
    row = @tweets.index(tweet)
    if row
      view.reloadRowsAtIndexPaths([NSIndexPath.indexPathForRow(row, inSection:0)], withRowAnimation:false)
    end
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
