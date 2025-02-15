# cs-doorLock

This is a Lua script that provides a menu for configuring doors in a game server, allowing administrators to customize door settings, including locking, job restrictions, and more. It is designed for use with the Mythic Framework.

## Features
- Configure door IDs, locked status, and double door settings.
- Add job-based access restrictions with customizable parameters.
- Supports the need for on and off duty statuses.
- Simple and Intuitive menu interface for ease of use.

## Installation
1. Clone the repository to your server.
   ```
    git clone https://github.com/Foxfire-Devs/cs-doorLock.git
   ```
2. Add the script to your server resources directory.
3. Ensure your server configuration file (eg. `server.cfg`) includes the following line to ensure the resource is loaded.
   ```
   ensure cs-doorLock
   ```

## Usage
1. Access the Door Management Menu:
   - Use the command `/doorLock` to open the menu.
2. Configure Door Properties:
   - **Door ID:** Enter a unique ID for the door (e.g., `mrpd_entranceDoor_1`).
   - **Double Door ID:** If your door is part of a double door setup, enter the second door's ID.
   - **Lock Status:** Choose whether the door is locked or unlocked.
   - **Restrictions:** Set job-based restrictions for accessing the door. You can configure the following:
     - Job Type (eg. `police`, `ems`)
     - Workplace Acess (eg. `lspd` or `false` for non)
     - Grade Level (numerical level for permissions)
     - Job Permission (true/false for specific job permissions)
     - Requires Duty (true/false if the user must be on duty to access)
3. Save and Select Door:
   - Once you have configured the door, click the "Save & Select Door" button to save the configuration.
4. Upload the created file:
   - Once created all yours doors you should now see a file in the `cs-doorLock` folder called `door_config.txt`.
   - Copy the contents of this to a new file within your `mythic-doors/shared/doorConfig/filename.lua`
5. Restart your Server

## Support
For Support, join our [discord](https://discord.gg/ReFfse53sf) and open a ticket! We will be happy to help where we can!

## Future Updates
- Gang Features
- Garage Doors
