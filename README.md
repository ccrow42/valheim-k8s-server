# Running a Valheim server with Password Rotation on Kubernetes

From: https://www.ccrow.org/2025/07/26/running-a-valheim-server-with-password-rotation-on-kubernetes/

It has been a long while since I have posted, mostly due to work having fun enough projects that my lab became a sort of second job. That isn't to say I wasn't tinkering, just that most of my time was going to the Kubernetes equivalent of weed pulling.

But then a bolt of inspiration happened after his kids wrecked a portion of our majestic mountain castle:

![This image has an empty alt attribute; its file name is valheim1.jpg](https://www.ccrow.org/wp-content/uploads/2025/07/valheim1.jpg)

![This image has an empty alt attribute; its file name is valheim2.jpg](https://www.ccrow.org/wp-content/uploads/2025/07/valheim2.jpg)

  
"If only you could change the password automatically"

In fairness to the kids "Dave" and "Normol the Red"... They only led the stone golem to the base. After a couple of play sessions of finger pointing comic book guy style bans (there is nothing funnier than a kid building a village just to ban the adults and his brother), I decided to get to work. This sounds like a job for someone with more time than sense...

![This image has an empty alt attribute; its file name is Screenshot_20250725_144815-1024x680.jpg](https://www.ccrow.org/wp-content/uploads/2025/07/Screenshot_20250725_144815-1024x680.jpg)

## Building on lloesche's excellent work

None of this would be possible without standing on the shoulder's of the giant that is lloesche using his excellent [Valheim server container](https://github.com/lloesche/valheim-server-docker). Seriously, star his repo and buy him a coffee and a puppy.

## Prerequisites

Besides the obvious Kubernetes cluster, we are going to need a few things for our server to work correctly:

First, we are going to need a place to store persistent data. I currently the [local-path-provisioner](https://github.com/rancher/local-path-provisioner) from the SUSE Rancher folks. This simply creates a local directory for every new PVC/PV that is created. You are welcome to use anything here.

Second, we need a load balancer (or configure a nodeport if you would like). My lab uses [Metallb](https://metallb.io/).

## Deploy Valheim to Kubernetes

I don't plan to show all of the YAML required to get this going, so instead, let's download the [repo](https://github.com/ccrow42/valheim-k8s-server) from github.com:

We can apply these files in order to deploy the Valheim server container:

This will apply all of the manifests required to get Valheim running. And for all those making fun of my inability to count due to my public school education,

You may wish to change `storageClass` in the `03-valheim-pvc.yaml` file:

and the service configuration in `05-valheim-service.yaml` if you are not using a load balancer:

The `type` can easily be changed to `nodePort`. Take note of the ports required for valheim to operate.

We now need to create a couple of secrets to make this work correctly. The secret reference can be found in the `04-valheim-deployment.yaml` file (we don't need to modify anything, but it is important to know what the `name` and `key` is for our secret:

The first is the server password. Don't worry about this too much as the entire point of this article is to be able to cycle the password automatically:

Now let's check on our service and port information so we know how to configure our firewall:

We would of course forward 2456-2457 UDP on our firewall to 172.42.3.32. We can stop now if all we want to do is build a Valheim server on Kubernetes, but you're here for the shenanigans.

## Rotating the Valheim server password

How to rotate this password was a hotly debated topic. Should I use a gitops pipeline to update a sealed secret and make sure ArgoCD bounces the pod? This seems like a lot of work to persist secrets in a git repo (generally a bad idea). Besides, our deployment shouldn't be hard-coding a password in the first place. Although the real reason is a such at writing gitlab actions.

Should I use an external secrets provider? This is probably the correct way and tell it to cycle the password. This did bring up the question about how to get the valheim pod to notice the change and restart (I suspect that this should be a sidecar, but I'm not sure). Either way, I don't have an external secrets provider configured... yet.

At the end of the day, any solution is going to require some custom scripting (It is funny how often things devolve to bash) so that I can notify people of the password change. I decided to go with a Kubernetes cronjob and a custom image to do the work.

I decided to use a simple list of dictionary words for the password. I also decided to use discord for notifications to a private channel.

## Building a custom image  


Our custom image is going to have a couple of helpful tools installed to do a password rotation. I was also lazy and baked the word list in to the image itself. I have also added a little script to notify Discord of the password change. It is a generic function, and will pull the Discord webhook URL from a secret. If you haven't generated a Discord webhook yet, see [these instructions](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks).

Let's take a look at a couple more files in our repo:

debian-custom/notify\_discord.sh

This file will be included in our image. Let's take a look at the Dockerfile:

We can now build and push our image:

Of course you will need to change the location where you are storing your image. My registry is not public.

Finally, let's create our webhook secret:

Be sure to use the webhook URL you created earlier.

## Creating the CronJob

Our cronjob is really the glue that makes this whole thing work. It starts by updating the password in the secret we created earlier. It then restarts the Valheim deployment (I don't bother to check if folks are on, if you are still playing at 4am than this is also your hint to go to bed). Lastly, it posts the password to the discord channel using the URL we stored in the above secret.

Because we are messing with some Kubernetes objects from our container, we need to create a service account the the proper permissions. Take a moment to review the configuration in the `valheim-password-rotation/service-account.yaml` file and apply it:

Now let's take a look at the CronJob itself:

valheim-password-rotation/rotate-password-cron.yaml

We pass a number of configuration variables, which if you have been following this guide you shouldn't need to change.

Be user to update the image on line 17.

Line 40 is where the magic happens using the `shuf` command. This logic would be easy to update if you would like a different password policy.

Once you are satisfied, let's apply the manifests and run a test job:

## Wrapping up

If all went well, you should see a discord notification trigger:

![This image has an empty alt attribute; its file name is image.png](https://www.ccrow.org/wp-content/uploads/2025/07/image.png)

I swear I did not plan that password...

This was a fun little project that I could wrap my walnut around given the arrival of our new baby (which also explains the numerous spelling and grammar mistakes).

One more fun idea... Don't give your kids the new password until they used the previous password in a sentence:  


![This image has an empty alt attribute; its file name is image-1.png](https://www.ccrow.org/wp-content/uploads/2025/07/image-1.png)

And there you have it, may your fires be warm and your homes unmolested by children!

![This image has an empty alt attribute; its file name is valheim3.jpg](https://www.ccrow.org/wp-content/uploads/2025/07/valheim3.jpg)
