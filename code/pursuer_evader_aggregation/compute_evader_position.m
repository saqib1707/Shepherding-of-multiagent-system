function [evader_position] = compute_evader_position(pursuer_position,Ne,iep,Ni,ti,vemax_repulsion,vemax_attraction,K)
    % Below part is just for verifying whether evaders and pursuer is following the control law
    % Reconstructing the path of the evader based on the pursuer path obtained from fmincon

    evader_position = zeros(Ne*2,Ni+1);
    evader_position(:,1) = iep;

    for i=1:Ni
        pursuer_evader_vector = reshape(evader_position(:,i),2,Ne) - repmat(pursuer_position(:,i),[1,Ne]);
        pursuer_velocity = pursuer_position(:,i+1) - pursuer_position(:,i);
        pursuer_evader_distance = sqrt(sum(pursuer_evader_vector.^2,1));
        costheta = (transpose(pursuer_velocity)*pursuer_evader_vector)./(pursuer_evader_distance*norm(pursuer_velocity));
        evader_position_sum = sum(reshape(evader_position(:,i),2,Ne),2);
        centroid_nearest_neighbour = (repmat(evader_position_sum,[1,Ne]) - reshape(evader_position(:,i),2,Ne))/(Ne-1);
        centroid_evader_vector = centroid_nearest_neighbour - reshape(evader_position(:,i),2,Ne);
        centroid_evader_distance = sqrt(sum(centroid_evader_vector.^2,1));
        repulsion_term = reshape(0.5*vemax_repulsion*repmat(exp(-K*pursuer_evader_distance).*(1+costheta),[2,1]).*(pursuer_evader_vector./repmat(pursuer_evader_distance,[2,1])),2*Ne,1);
        attraction_term = reshape(vemax_attraction*repmat(exp(-K*pursuer_evader_distance),[2,1]).*(centroid_evader_vector./repmat(centroid_evader_distance,[2,1])),2*Ne,1);
        evader_position(:,i+1) = evader_position(:,i) + repulsion_term*ti + attraction_term*ti;
    end
end