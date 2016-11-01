# DataSampler

This is a port of my NotificationHubTest iOS app to Swift 3. I have attempted to refactor it into a more general
data sample recording and visualization application. Both apps rely on
[Core Plot](https://github.com/core-plot/core-plot) for visualization, but DataSampler also has additional
dependencies to do its job.

- [CircleProgressView](https://github.com/CardinalNow/iOS-CircleProgressView) — displays a cicular progress view
  indicator in table view cells during Dropbox uploads
- [InAppSettingsKit](https://github.com/futuretap/InAppSettingsKit) — provides a great in-app view of
  user-customizable settings
- [JSQCoreDataKit](https://github.com/jessesquires/JSQCoreDataKit) — a Swift Core Data stack that makes working
  with Core Data a bit less painful and surprising
- [MGSwipeTableCell](https://github.com/MortimerGoro/MGSwipeTableCell) — offers swipe-to-reveal action buttons
  for table view cells, on both left and right side of the cell
- [SwiftyDropbox](https://github.com/dropbox/SwiftyDropbox) — Swift Dropbox SDK

These dependencies are listed in the [CocoaPods](https://cocoapods.org) `Podfile`. To build, you will need to
first perform

    % pod install

in the top-level directory of your source's clone.

# Usage

Right now the application only supports a demonstration mode which generates synthetic data. However, this is
enough to see the functionality that the app contains. The app contains three views, selected by the icons at
the bottom. The first view shows the Core Plot graphs that visualize the samples received during a recording
session. The top half of the display shows a scatter plot of received sample data, with the X axis representing
elapsed time and the Y access latency values calculate from the received samples. Below this plot, there is a
bar chart which represents a histogram of latency values, each histogram bin representing one second.

![plots](images/mainScreen.png?raw=true)

At the top left there is a start button (green arrow) which will start a new recording session. To the
right there are three buttons which control the lower view. The first button shows the historgram plot mentioned
above. The second button shows log messages emitted by the application during the recording session. Finally,
the third button reveals an *events* view which is simply a collection of comma-separated values (CSV) of
notable events. Using the CSV format allows easy importing into applications such as Apple's Numbers or
Microsoft's Excel.

![log view](images/logView.png?raw=true)
![event view](images/eventView.png?raw=true)

## Recordings

The second button at the bottom of the screen brings up a list of active and past recordings. Clicking on a
recording will make it current, updating the plots and logs of the first screen to show the recorded data.
Recordings may be shared using the iOS sharing facility, and they may also be uploaded to a Dropbox account once
you have gone through the Dropbox linking procedure which is reached on the settings screen described below.

![recordings](images/recordingsScreen.png?raw=true)

The uploading and sharing buttons appear when you swipe a recording cell to the right; swiping to the left
reveals a delete button for erasing the recording from the device. Double-tapping a recording will make it
current and switch you back to the first screen with the plots.

Each recording contains three files:

- PDF render of the plots
- Text file of the log lines
- Text file of the CSV data

You can share these files via any supported sharing mechanism on iOS. If you link the app to your Dropbox
account, the application will create a directory made up of the start date/time of the recording in the app's
Dropbox root directory, and the app will copy the three files listed above from the device to the newly-created
directory.

## Settings

The third and final screen in the application shows various configuration options (most of these can also be
manipulated through the iOS Settings app). In the app view, there is a button which controls Dropbox linking.

![settings](images/settingsScreen.png?raw=true)

