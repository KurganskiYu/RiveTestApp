# Rive Test App

## Overview

I need you to create an application to test my Rive animations before delivering to the developers. Basically, I already have what I need in a web form. Take a look at my web tester script. Generate_HTML Python script that takes data from the CSV file. It makes a simple web catalogue of my Rive animations. I want you to plan and make the same application but for iOS. It should use the same CSV file, which I will be manually updating all the time. But I want the architecture of this application to be as professional as possible. But not overcomplicated. I value simplicity and cleanliness. So my web version of the catalogue generates a lot of HTML files. We probably don't need that in our application, and we could probably generate all the pages on the fly. I guess. I will rely on you on this one.

It's important to know that if you have any questions about how to do things, you should be orienting on the existing generate HTML Python script. Almost all the logic you need is already there. So I will not describe how it's working by reading a CSV file and managing the data.

Same as for the website, I will put Rive animations .riv files to the riv folder manually and update the CSV file.

## Catalog pages

I think the application should look more or less like my website version. There is a catalog pages with 4-8 rive animations per page. But I don't need to show any parameters on these pages as I do in the web version. Also, I don't want it to be interactive, as Rive files can be. Because I want to swipe from page to page, and then we should be able to press any animation to proceed to its own screen.

Animations should be placed on these catalog pages the same way as on the side, like two rows with the same horizontal size for each animation and the small gap between them. Choose the best way of doing that. The reason why I don't want to implement infinite scroll is that Rife animations could be demanding. So we can show not more than eight animations per page.

## Animation Screen

And that's where we can show an interactive animation with the parameters that we can edit, and there is often a preview animation. This part I am also not sure how to do in the best way. We should probably need a scroll bar on the right. Because I want animations to be a little bit smaller than the screen size. But often animations are full-screen iPhone animations, so we should be able to scroll down to the parameters. Oh, I think I know what I want. We don't need the scroll. We need a bottom menu bar. On that bottom bar, there should be a button to switch between the main animation and the preview animation. Also, there should be a button to show a parameters floating window. And the third thing that should be in that menu bar is a trigger button when it's needed, Because not all animations have triggers, but if they do, we should show the button.

We should be able to tweak the design later. I will probably do this bottom menu bar with the Rive. Because Rive functionality allows doing menus and other stuff. But for now, let's make it simple with iOS standars functionality.

On this animation screen, I want the Rive Interactive functionality to be working. So we should not be blocking pointer interactions on this screen as we do on the catalog pages.

## Parameters and Data Binding

This is the most important part. As I want this app to be a testing app, we should bind all the necessary parameters and be able to change them interactively. To make this right, I need you to check Rive Documentation. I placed a path to the Rive iOS package in a separate file. You can find examples there and other stuff that you might need. The important thing is that Rive updated the iOS implementation, so there is a new way and a legacy way. So make sure you use the new one. We are not going to use the legacy way.

Documentation:

- [Rive iOS Source](https://github.com/rive-app/rive-ios/tree/main/Source)
- [Rive Apple Runtime Docs](https://rive.app/docs/runtimes/apple/apple)
