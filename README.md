# package_scanner

This app was designed to manage cargo packages in a warehouse. This app uses http-posts to communicate with a server script (PHP) to manage SQL tables.

This app facilitates two SQL tables:

-Inventory: Stored Packages in the warehouse defined by bar code, location code, quantity and description

-Outgoing Packages: Packages which are ready to be sent and are defined by package id, tracking number and additional notes


<img src="https://github.com/Ethernull/flutter_package_management_scanner/blob/master/screenshots/create_entry0.jpg" alt="alt text" width="200" height="400">
<img src="https://github.com/Ethernull/flutter_package_management_scanner/blob/master/screenshots/scan_barcode.jpg" alt="alt text" width="200" height="400">
<img src="https://github.com/Ethernull/flutter_package_management_scanner/blob/master/screenshots/create_entry1" alt="alt text" width="200" height="400">
<img src="https://github.com/Ethernull/flutter_package_management_scanner/blob/master/screenshots/view_table.jpg" alt="alt text" width="200" height="400">
<img src="https://github.com/Ethernull/flutter_package_management_scanner/blob/master/screenshots/update.jpg" alt="alt text" width="200" height="400">
<img src="https://github.com/Ethernull/flutter_package_management_scanner/blob/master/screenshots/delete.jpg" alt="alt text" width="200" height="400">


This was app was made possible thanks to:

https://github.com/AmolGangadhare/flutter_barcode_scanner (MIT License)

https://github.com/dart-lang/http (BSD-3-Clause License)

https://github.com/MarcinusX/NumberPicker (BSD-2-Clause License)

And of course

https://github.com/flutter/flutter (BSD 3-Clause)


Have a nice day!



