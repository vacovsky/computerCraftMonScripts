package main

import (
	"log"

	"github.com/fsnotify/fsnotify"
)

var WATCHED_FILES = []string{
	// Mekanism and stuff
	`E:\minecraft_servers\direwolf20_1.12\world\computercraft\computer\40\monitorData.json`,

	// Trona  colonyIntegrator
	`E:\minecraft_servers\direwolf20_1.12\world\computercraft\computer\28\monitorData.json`,

	// Magic Town colonyIntegrator
	`E:\minecraft_servers\direwolf20_1.12\world\computercraft\computer\1\monitorData.json`,

	// Witch Hazel colonyIntegrator
	`E:\minecraft_servers\direwolf20_1.12\world\computercraft\computer\42\monitorData.json`,

	// AE2 storage  general
	`E:\minecraft_servers\direwolf20_1.12\world\computercraft\computer\33\monitorData.json`,

	// AE2 nuclear items tracker
	`E:\minecraft_servers\direwolf20_1.12\world\computercraft\computer\41\monitorData.json`,

	// Magic Town (Paradise Hills) crafting requests served counter
	`E:\minecraft_servers\direwolf20_1.12\world\computercraft\computer\44\requestsServed.json`,

	// Trona crafting requests served counter
	`E:\minecraft_servers\direwolf20_1.12\world\computercraft\computer\43\requestsServed.json`,

	// Witch Hazel crafting requests served counter
	`E:\minecraft_servers\direwolf20_1.12\world\computercraft\computer\45\requestsServed.json`,
}

func main() {

	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal("NewWatcher failed: ", err)
	}
	defer watcher.Close()

	done := make(chan bool)
	go func() {
		defer close(done)

		for {
			select {
			case event, ok := <-watcher.Events:
				if !ok {
					return
				}
				// file change detected
				log.Printf("%s %s\n", event.Name, event.Op)
				// read in file to JSON
				// jsonFile, err := os.Open("users.json")
				if event.Op == fsnotify.Write {
					ingestMonitorDataToRedis(event.Name)
				}
			case err, ok := <-watcher.Errors:
				if !ok {
					return
				}
				log.Println("error:", err)
			}
		}

	}()

	for _, file := range WATCHED_FILES {

		err = watcher.Add(file)
	}
	if err != nil {
		log.Fatal("Add failed:", err)
	}
	<-done

}
