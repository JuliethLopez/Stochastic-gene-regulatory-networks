# libraries
library(rlist)
library(igraph)
library(gtools) 
library(markovchain)
library(data.table)
library(RColorBrewer)
library(dplyr)

###############################################################
# class gen
gen = setClass("gen", slots = list(name="character",
                                   state="numeric",
                                   temp_state="list",
                                   activate_list="list",
                                   inhibit_list="list",
                                   prob_activation="numeric",
                                   prob_degradation="numeric"
                                   ))

# class network
network = setClass("network", slots = list(gen_list="list",
                                           num_gens="numeric",
                                           fixed_states="matrix",
                                           gen_dict="list",
                                           all_states="matrix",
                                           propensities="matrix",
                                           transition_matrix="matrix"))

###############################################################
# function reference gen names
ref_gen_names = function(object){
  new_list = list()
  for(gen in object@gen_list){
    new_list[[gen@name]] = gen} #the dictionary connect the gene name with the complete gene
  object@gen_dict = new_list
  return(object)
}

# funtion that plots the genes dynamic
plot_gens = function(input_gen_list){
  dinamic = c()
  for(gen_from in input_gen_list){
    if(length(gen_from@activate_list)!=0){
      tab=cbind(gen_from@name,unlist(gen_from@activate_list),"green3")
      dinamic=rbind(dinamic,tab)
  }}
  for(gen_from in input_gen_list){
    if(length(gen_from@inhibit_list)!=0){
      tab=cbind(gen_from@name,unlist(gen_from@inhibit_list),"red2")
      dinamic=rbind(dinamic,tab)
    }}
  gd=graph.data.frame(d = dinamic,directed = T)
  plot.igraph(gd, edge.curved = T, edge.color=dinamic[,3], vertex.color="grey",
              main="Genes interaction", margin=0.2)
  legend(x = "topleft",
         legend = c("Activation", "Degradation"),
         pch = 19,
         col = c("green3","red2"),
         bty = "n")
}

# function that obtain all the possible states
get_all_possible_states = function(object){
  object@all_states=permutations(2,object@num_gens,c(0,1),repeats.allowed = T)
  return(object) #in order: A, B and C
}

# function that fixed the current state (from the possible)
set_current_state = function(object, state){
  for(i in 1:length(state)){
    object@gen_list[[i]]@state=state[i]
  }
  return(object)
}

# function used to obtain the next state for each gene
real_state = function(data){ 
  result = sum(unlist(data))%%2
  return(result)
}

#function that obtain the next state of all genes based on the current state
get_current_state=function(object){
  state_vector = c()
  for(gen in object@gen_dict){
    gen@state = real_state(gen@temp_state)
    gen@temp_state = list()
    state_vector = c(state_vector, gen@state)
  }
  return(list(object, state_vector))
}

#function that conditioned the next stated to the previous to obtain states with sense
get_new_state = function(signal, previous_state){
  if((signal == 0 & previous_state == 0) | (signal == 0 & previous_state == 1)){
    return(0)}
  else{
    return(1)
  }
}

#Process detailed for states actualization using the functions made before
execute_gen=function(object, gen){
  #print(paste("EXECUTING",gen@name))
  for(name_to_active in gen@activate_list){
    #print(paste("ACTIVANDO", name_to_active))
    gen_to_active = object@gen_dict[[name_to_active]]
    #print(paste("SIGNAL", gen@state, "OLD SATE:", gen_to_active@state))
    gen_to_active@temp_state=append(gen_to_active@temp_state,get_new_state(gen@state,gen_to_active@state))
    #print(get_new_state(gen@state,gen_to_active@state))
    #print(paste("NEW TEMP STATE:", gen_to_active@temp_state))
    object@gen_dict[[name_to_active]] = gen_to_active
  }
  for(name_to_inhibit in gen@inhibit_list){
    #print(paste("INHIBIT", name_to_inhibit))
    gen_to_inhibit = object@gen_dict[[name_to_inhibit]]
    #print(paste("SIGNAL", gen@state, "OLD SATE:", gen_to_inhibit@state))
    gen_to_inhibit@temp_state=append(gen_to_inhibit@temp_state, as.numeric(!get_new_state(gen@state, gen_to_inhibit@state)))
    #print(paste("NEW TEMP STATE:", gen_to_inhibit@temp_state))
    object@gen_dict[[name_to_inhibit]] = gen_to_inhibit
  }
  #print("gene executed")
  return(object)
}

#Use the last function for the states but also save the information
get_nodes=function(object, state){
  object=set_current_state(object,state)
  object=ref_gen_names(object)
  for(i in seq(object@num_gens)){
    curr_gen=object@gen_list[[i]]
    object=execute_gen(object,curr_gen)
  }
  #print("get_nodes completed")
  return(object)
}

#Gets the fixed states between the all posible states
fixed_states=function(object){
  result_list=list()
  for(i in 1:nrow(object@all_states)){
    state=object@all_states[i,]
    #print("calculating state")
    #print(state)
    object=get_nodes(object,state)
    #print("RESULT")
    result = get_current_state(object)
    object = result[[1]]
    new_state = paste(result[[2]],collapse = "")
    #print(new_state)
    state_string = paste(state,collapse = "")
    result_list=append(result_list,c(state_string, new_state))
  }
  object@fixed_states = matrix(unlist(result_list), ncol=2, byrow=T)
  #print(object@fixed_states)
  return(object)
}

#Show fixed states
show_table = function(object){
  all_states=object@fixed_states[,1]
  n_states=length(all_states)
  prob=matrix(0,n_states,n_states)
  rownames(prob) = all_states
  colnames(prob) = all_states
  for(i in 1:n_states){
    index=object@fixed_states[i,]
    prob[index[1],index[2]]=1
  }
  return(prob)
}

#Plot netwwork with fixed states
plot_graph=function(P){
  mc = new("markovchain",transitionMatrix=P,name="States")
  plot(mc,edge.curved = T)
  title("Network")
}

#Obtain the initial propensities from all the genes
obtain_propensities=function(object){
  propensities=matrix(0, nrow = 2, ncol = object@num_gens)
  for(i in 1:object@num_gens){
    propensities[1,i]=object@gen_list[[i]]@prob_activation
    propensities[2,i]=object@gen_list[[i]]@prob_degradation
  }
  object@propensities=propensities
  return(object)
}

#Calculate the transition matrix using the propensities
transition_matrix=function(net){
  propensities=net@propensities
  transition_matrix=matrix(0, nrow = nrow(net@all_states), ncol = nrow(net@all_states))
  #initial state
  for(initial in 1:nrow(net@all_states)){
    fixed_state=strsplit(net@fixed_states[initial,], split = "")
    x=as.numeric(fixed_state[[1]])
    f=as.numeric(fixed_state[[2]])
    #new state
    for(new in 1:nrow(net@all_states)){
      y=net@all_states[new,] #states
      prob=1
      for(i in 1:net@num_gens){ #gens
        c=0
        if(x[i]<f[i]){
          if(y[i]==f[i]){
            c=propensities[1,i]
          }
          if(y[i]==x[i]){
            c=1-propensities[1,i]
          }
        }
        if(x[i]>f[i]){
          if(y[i]==f[i]){
            c=propensities[2,i]
          }
          if(y[i]==x[i]){
            c=1-propensities[2,i]
          }
        }
        if(x[i]==f[i]){
          if(y[i]==x[i] | y[i]==f[i]){
            c=1
          }
          else{
            c=0
          }
        }
        prob=prob*c
      }
      transition_matrix[initial,new]=prob
    }
  }
  rownames(transition_matrix)=colnames(transition_matrix)=net@fixed_states[,1]
  net@transition_matrix=transition_matrix
  return(net)
}

#Calculate beta parameters with sense
BetaParams <- function(mu) {
  alpha = 0 
  beta = 0
  while (alpha <= 0 | beta <= 0) {
    var = runif(1)
    alpha <- ((1-mu)*mu^2-mu*var)/var
    beta <- (alpha*(1-mu))/mu
  }
  return(params = list(alpha = alpha, beta = beta))
}

#Function that calculate values to simulate networks
make_simulations = function(net,n){
  propensity.matrix.act <- matrix(0,nrow=n,ncol=net@num_gens)
  propensity.matrix.deg <- matrix(0,nrow=n,ncol=net@num_gens)
  
  for (i in 1:nrow(net@propensities)){
    for (j in 1:ncol(net@propensities)){
      mu = net@propensities[i,j]
      values <- BetaParams(mu)
      random.variable <- rbeta(n,values$alpha,values$beta)
      if (i == 1){ 
        propensity.matrix.act[,j] = random.variable}
      else{
        propensity.matrix.deg[,j] = random.variable}
    }
  }
  return(list(propensity.matrix.act=propensity.matrix.act, propensity.matrix.deg=propensity.matrix.deg))
}

#Function that simulate networks using information obtaines in the last funcion
propensities_simulation= function(net,simulations){
  propensities_simulations = matrix(0,nrow=length(net@transition_matrix),ncol=100)
  for (i in 1:100){
    for (j in 1:net@num_gens){
      net@gen_list[[j]]@prob_activation = simulations$propensity.matrix.act[i,j] 
      net@gen_list[[j]]@prob_degradation = simulations$propensity.matrix.deg[i,j] 
    }
    #propensities matrix
    net=obtain_propensities(net)
    #transition matrix
    net=transition_matrix(net)
    propensities_simulations[,i] <- as.vector(net@transition_matrix) #The values of the transition matrix of the simulations are stored in columns, each column contain the values of a matrix. For make the matrices, R takes a vector (in this case a column) and by default orders the values by columns.
  }
  var.simulations <- apply(propensities_simulations, 1, var)
  var.matrix <- matrix(var.simulations,nrow=nrow(net@transition_matrix),ncol=ncol(net@transition_matrix)) #the matrix takes a vector and order the values by columns
  rownames(var.matrix) = net@fixed_states[,1]
  colnames(var.matrix) = net@fixed_states[,1]
  return(list(propensities_simulations=propensities_simulations, var.matrix=var.matrix))
}

#plot the simulation
plot_graph_simulations= function(initial.trans.matrix,propensities_simulations,ceros=FALSE){
  melt(data.table(initial.trans.matrix, keep.rownames=T),id="rn")
  color=colorRampPalette(c("deepskyblue", "darkgreen"))(nrow(initial.trans.matrix))
  
  matriss_complete=melt(data.table(initial.trans.matrix, keep.rownames=T),id="rn")
  matriss1=melt(data.table(propensities_simulations$var.matrix, keep.rownames=T),id="rn")
  matriss_complete$var=matriss1$valu
  summary_var=summary(matriss_complete$var)
  matriss_complete=matriss_complete[order(matriss_complete$var),]
  matriss_complete$color=rep(color,rep(8,8))
  if (ceros==TRUE){
    matriss_filtered=matriss_complete
  } else {
    matriss_filtered=matriss_complete%>%filter(value!=0)
  }
  
  gd=graph.data.frame(d = matriss_filtered,directed = T)
  plot.igraph(gd,edge.curved = T,edge.width=matriss_filtered$var/(0.3*max(matriss_filtered$var)),
              edge.col=matriss_filtered$color, margin=0.2,
              edge.label=matriss_filtered$value,main="Simulations network")
  legend(-1.9,1.2,
         legend = paste(names(summary_var[c(1,3,6)]),round(summary_var[c(1,4,6)],2), sep = ":"),
         lty=1,
         lwd=summary_var[c(1,4,6)]/(0.3*max(matriss_filtered$var)),
         col=color[c(1,4,8)],
         bty = "n")
}

complete_simulation = function(input_gen_list,num_simulations=100,ceros=FALSE){
  #We plot the genes dynamic
  plot_gens(input_gen_list)
  
  #We define the network
  net=network(gen_list=input_gen_list, num_gens=length(input_gen_list))
  
  #Calculte the states
  net=get_all_possible_states(net)
  net=ref_gen_names(net)
  net=fixed_states(net)
  
  #matrix states
  P=show_table(net)
  
  #plot states
  plot_dinamic=plot_graph(P)
  
  #propensities matrix
  net=obtain_propensities(net)
  initial_propensities=net@propensities
  
  #transition matrix
  net=transition_matrix(net)
  initial.trans.matrix = net@transition_matrix
  plot_graph(initial.trans.matrix)
  
  #Simulations
  simulations = make_simulations(net,n=num_simulations)
  propensities_simulations = propensities_simulation(net,simulations)
  var_simulation = propensities_simulations$var.matrix
  
  #graph with the variance of the simulations
  plot_graph_simulations(initial.trans.matrix,propensities_simulations,ceros)
  
  return(list(genes=input_gen_list, matrix_states=P, initial_propensities=initial_propensities,
              initial.trans.matrix=initial.trans.matrix, var_simulation=var_simulation,
              net=net, propensities_simulations=propensities_simulations))
}
