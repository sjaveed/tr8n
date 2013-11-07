# Welcome to Tr8n Translation Engine

Tr8n Translation Engine is a Rails Engine Plugin/Gem that provides a platform for crowd-sourced translations of your Rails application.
The power of the engine comes from its simple and friendly user interface that allows site users as well as professional translators to rapidly 
translate the site into hundreds of languages. 

The rules engine that powers Tr8n allows translators to indicate whether sentences depend on gender rules, numeric rules or combinations of rules configured for each language.
The language specific context rules and language cases can be registered and managed in the administrative user interface. The engine
provides a set of powerful tools that allow admins to configure any aspect of the engine; enabling and disabling its features
and monitoring translation progress.


![alt text](https://raw.github.com/tr8n/tr8n/master/doc/screenshots/tr8nlogo.png "Tr8n Logo")



Tr8n translation engine has been successfully deployed by Geni and Yammer:

Geni Inc, http://www.geni.com

Yammer Inc, http://www.yammer.com 



# Documentation

Documentation is available on Tr8n's wiki site:

http://wiki.tr8nhub.com


# Installation Instructions

Add the following gems to your Gemfile: 

```ruby
  gem 'will_filter', "~> 3.1.2" 
  gem 'tr8n', "~> 3.2.1" 
```

And run:

```sh
  $ bundle
```

At the top of your routes.rb file, add the following lines:

```ruby
  mount WillFilter::Engine => "/will_filter"
  mount Tr8n::Engine => "/tr8n"
```

To configure and initialize Tr8n engine, run the following commands: 

```sh
  $ rails generate will_filter
  $ rails generate tr8n
  $ rake db:migrate
  $ rake tr8n:init
  $ rails s
```

Open your browser and point to:

  http://localhost:3000/tr8n


# Integration Instructions

The best way to get going with Tr8n is to run the gem as a stand-alone application and follow the instructions and documentation in the app:

```sh
  $ git clone git://github.com/tr8n/tr8n.git
  $ cd tr8n/test/dummy
  $ bundle install
  $ rake db:migrate
  $ rake tr8n:init
  $ rails s
```

Open your browser and point to:

  http://localhost:3000


# Tr8n Screenshots

Below are a few screenshots of what Tr8n looks like:

## Tr8n Language Selector

![alt text](https://raw.github.com/tr8n/tr8n/master/doc/screenshots/language_selector.png "Tr8n Language Selector")

## Tr8n Inline Translator

![alt text](https://raw.github.com/tr8n/tr8n/master/doc/screenshots/submit_translation.png "Tr8n Inline Translator")

## Tr8n Translation Voting

![alt text](https://raw.github.com/tr8n/tr8n/master/doc/screenshots/vote_on_translation.png "Tr8n Translation Voting")

## Tr8n Translation Tools

![alt text](https://raw.github.com/tr8n/tr8n/master/doc/screenshots/translation_tools.png "Tr8n Translation Tools")

## Tr8n Translation Admin Tools

![alt text](https://raw.github.com/tr8n/tr8n/master/doc/screenshots/admin_tools.png "Tr8n Admin Tools")


# External Links

Yammer in Translation

http://bit.ly/g5GQDt 

Yammer Now Available in Dutch, French, German, Japanese, Korean, and Spanish

http://bit.ly/heNIPr 


Geni Goes Global With 20 New Languages And A Crowdsourced Translation Tool 

http://tcrn.ch/f1VLnj 

Quora Discussion - What is the best way to deal with internationlization of text on a large social site?

http://bit.ly/hUU6R9 


