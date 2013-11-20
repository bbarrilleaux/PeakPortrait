require 'thin'
require 'sinatra'
require 'slim'
require 'rinruby'
require 'pry' 

set :slim, :pretty => true

get '/' do
  R.keys = ["that","here","where","and","from"]
  R.counts = [4,6,7,7,3]
  total=3
  R.eval <<EOF
   names(counts) <- keys
   png("stuff.png")
      barplot(sort(counts),main="Frequency of Non-Trivial Words")
  #    mtext("Among the #{total} words in the Gettysburg Address",3,0.45)
      dev.off()
      rho <- round(cor(nchar(keys),counts),4)
EOF

   puts "The correlation between word length and frequency is #{R.rho}."
end

