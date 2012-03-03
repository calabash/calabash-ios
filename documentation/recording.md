Touch recording and playback
=================================

Calabash iOS supports synthesizing complex touch events. This works by
recording a sequence of touch events as you perform them on a
simulator or device. The recorded sequence can then be played back as
part of a step in a cucumber feature.

It is important to stress the difference between this type of gesture
recording and test recorders (for example,
Selenium IDE for web). Test recorders generate test scripts, and the
generated output is often not very good, leading to unmaintainable
tests (it is not written in the language of your business domain, and
is too specific meaning that tests break with minor UI changes).

Instead Calabash iOS supports recording complex touch events. Examples
of complex touches could be panning (drag-drop), pinch, swipe or
multi-touch events. These are only intended to be played back as a
single custom step in a Calabash test and are not intended to be
entire test suites.

An example
----------
In a music player app, you could have a custom step

    Then I move "Tears in Heaven" to the top of the playlist

This would drag a cell with the song Tears in Heaven by Eric Clapton
to the top of a playlist using the reorder control in a UITableView.

Panning or dragging is not part of what Calabash iOS supports out of
the box. But you could record a touch event sequence where you drag a
cell one up the list using the reorder control. Let's call this
recorded sequence "drag\_one_up". Then you could implement the custom
step above as follows:

    Then /^I move "([^"]*)" to the top of the playlist$/ do |text|
        #query for the table cell with the track
        cell = "label marked:'#{text}' parent tableViewCell"
        #query for the reorder control for the track
        reorder_control = "#{cell} descendant tableViewCellReorderControl"
        #query to check if the track is at index 0
        is_at_top = "tableViewCell index:0 label marked:'#{text}'"
        while query(is_at_top).empty? do
            playback "drag_one_up", {:query => reorder_control}
        end

    end

The idea is to keep moving the track one up until it is at the top of
the list. The first assignment defines a query that finds the cell
containing the track to move. The second assignment defines a query
that finds the reorder control inside the cell containing the
track. The query `is\_at_top` checks if the track is at the top of the
table view (this assumes that the table is scrolled to top).

The test proceeds by playing back your recorded drag-drop touch events
on the reorder control for the track. This continues until the track
is at the top of the list. Notice the line

    playback "drag_one_up", {:query => order_control}

This shows playback in action! Not only can you playback a recorded
sequence of touch events, but you can relocate where the playback
starts. So your recording acts like a prototype (e.g. defining how to
move a track up the playlist), but can be played back on any view or
coordinate. This is really powerful.

Recording
---------

This is a slightly advanced feature that requires that you can use the
Calabash iOS console. Start your app in simulator and move it to the
state just before you want to start recording (it is also possible to
record on device, but this example uses simulator for simplicity). Now
start the Calabash console using the OS and DEVICE that you are
recording on:

    krukow:~/apps$ OS=ios5 DEVICE=iphone ./irb_ios5.sh

(Note that you must record your touch events for both iOS4 and iOS5 - this is because unfortunately touch events are represented differently on each os).

Now use the command `record_begin`

    irb(main):001:0> record_begin
    => ""

This begins recording touch events. Now in the simulator perform the
touch events you want to record. This should be a short sequence of
events corresponding to a gesture on a view.
Then use `record_end "mytouches"`, for example

    irb(main):002:0> record_end "drag_one_up"
    => "drag_one_up_ios5_iphone.base64"

This saves the touch events under the name "mytouches". In the example, you see the string "drag\_one\_up\_ios5_iphone.base64". This is actually a file being saved in your directory.

You can test that the recording does what it should by running

    irb(main):003:0> playback "drag_one_up"
    => ["<UIView: 0x7dc70b0; frame = (-48.7356 26.2644; 417.471 417.471); ...

This will playback the events you just recorded at the same coordinates you recorded them. If you're unhappy with the results just try again.

If you're happy, exit the console and move the generated file to the "features" folder.

Playback
--------

Put your recorded touch events  in the `features` folder. You can playback using the api function  `playback`. You must specify which file to playback.

You have the option of moving the start coordinate for the touch events. This is most commonly used to move a recorded touch sequence to a different view that where it was recorded. This is done using the query option:

    `playback "mytouches", {:query => "view marked:'acclabel'}

The `playback` function also supports an offset option to further move the start of the touches.
