# Programming Languages Final 

![10k](./10k.png)
![100](./100.png)
[Presentation Slides](https://docs.google.com/presentation/d/1YJ6y-OqhqbdBB83UA-Bn3SIxVDrKccWJgN9v8z2yp0A/edit?usp=sharing)

---

## What It Is

This project is a Perl web crawler / scraper which crawls through websites in a round robin style. We start at four beginning websites (one is whitworth), and crawl one at a time through these starting URL's adding scraped href websites to a priority queue. Then, we use those scraped websites to continuously scrape other websites and so and and so forth.

When we go through a website, we gather interesting metadata such as the number of how many other websites that we've scraped reference this website, what response code we get when trying to scrape this website, and how long it took us to initially scrape the url's dom elements. 

## Justification 

As opposed to my LM8 Perl web crawler, this project goes beyond by collecting and visualizing metadata in interesting ways in order to help people answer key questions like, "which websites can I automatically scrape data from?" or "I wonder which domains fill up a majority of the internet?". The data storage of this project is naive at best (json file), and the perl microservice doesn't at all directly interopt with the frontend static html page. The visualization of this project is what I hoped would make this project shine, and I've cited key resources to how this was made possible at the end of this document. 

## Running the Project

Right now, I have a [web crawler file](./crawler.pl), a [singular html file](graph_clustered.html), a [json file](./data/graph.json) which is generated after the web crawler runs, a [text file](./urls.txt) which contains the urls which we start crawling from, and a [file that runs the program](run_graph.pl).

In order to run the program, we only care about the last referenced file, it should be named run_graph.pl. 

In order to run the project, there are two main steps that must be accomplished: 
1. Run the web crawler
2. Open the HTML file on a port

### 1. Run the web crawler

Open a terminal and run the run_graph.pl file. When you run this file, there are two flagged parameters that must be set: where you're going to start web crawling from, and how many pages you want to crawl. 

I would recommend running 
```bash
 perl run_graph.pl --urls urls.txt --max 10
```
for a quick analysis of the graph. If this works, you can adjust both flags and see what works for you. I would **highly** recommend staying under 1,000 for the number of pages that you crawl. Not because the web crawler will take a long time, but because the loading of the html file could be horrendous. 

For reference, loading 10,000 URL's took my laptop around two hours just to crawl the websites. This was greatly influenced by the fact that I return non success response codes for 300 codes which don't really need to be done. Because of the way that my code is structured, non success response codes take a lot longer than success response codes, which also just intuitively makes sense. Then, it took another three minutes for the html file to load. 

### 2. Open the HTML file on a port

I know this next part is bad, but I did what I could in the amount of time that I had during finals week. The file that you just ran actually ran the web crawling file as well. The web crawling file then grabbed and logged all of the data needed for the graph inside of the graph.json file. The HTML file locally references, opens, and uses this json file in order to graph everything. This means that you can't just open the html file on your laptop, you'll need to open a port. 

If you're on VSCode and you have the live server extension, just click on the 'Go Live' button on the bottom right of your IDE. If that button doesn't exist, type this

```bash
 python3 -m http.server 8000     
```

If python3 doesn't exist, try python. If python also doesn't work, install python. 

**Then, go to this link**: http://localhost:8000/graph_clustered.html

### If you want to load the 10k data graph

The html file loads the data directly from the json file. The line of code looks like this 

```html
d3.json("./data/graph.json").then(graph =>
```

Change the graph.json name to 10k.json and follow the above final step. You do not need to rerun the entire program, I did it once and saved it so it'll never have to be done again. 

## Challenges Faced

The main challenge that I faced during this project was clustering similar domain names on visual represention of the nodes of the graph. Adding status response code checks was not hard, creating the visualization was not hard, gathering the relavant data was not extremely hard either. The hardest part was definitely clustering urls. 

In the scope of this project, clustering is defined as the process of grouping pages (nodes) together based on their URL domain names. Pages that originate from the same domain name are placed into the same cluster, highlighting how websites internally link their own pages.

This is NOT a markov chain, and this is definitely NOT natural language processing yet. 

## Future Work

I hope to continue this project, at least a little, in order to improve my clustering method. Perl is known excel at NLP, and I think that if I could cluster websites by domain named based on NLP, that could be cool. I also hope to possibly crawl through a specific website's pages and cluster different topics that each page talks about using NLP. For example, if we start on the BBC news's home page, we could crawl through all of the linked bbc pages, and when we go through those pages, by using NLP, determine what the topic of the page is about. Then, we can assign a one word definition for this page and attach that to the nodes of our graph. Then, we can visualize which topics were most talked about within the bbc domain using natural language process clustering based on topics, not only domain names. 

## Citations

- https://flowingdata.com/2012/08/02/how-to-make-an-interactive-network-visualization/
- https://perldoc.perl.org/
- https://stackoverflow.com/questions/10897748/how-to-implement-a-stopwatch-timer-in-perl
- https://stackoverflow.com/questions/402377/using-getopts-to-process-long-and-short-command-line-options
- https://perldoc.perl.org/File::Spec
- https://metacpan.org/pod/LWP::UserAgent
- https://perldoc.perl.org/Digest::MD5
- https://metacpan.org/pod/Digest::Perl::MD5
- https://stackoverflow.com/questions/1037783/how-can-i-calculate-the-md5-hash-of-a-wav-file-in-perl
- https://stackoverflow.com/questions/2667229/how-can-i-build-and-parse-http-urls-uris-paths-in-perl
- https://stackoverflow.com/questions/3839358/how-can-i-parse-user-agent-strings-in-perl