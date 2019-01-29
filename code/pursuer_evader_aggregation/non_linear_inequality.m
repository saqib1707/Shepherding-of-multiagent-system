function [cieq] = non_linear_inequality(x, var, Ni, Ne, ti, ip, vpmax, epsilon)
    parameters = horzcat(ip,reshape(x,var,Ni));
    final_centroid = mean(reshape(parameters(1:Ne*2,Ni+1),2,Ne),2);
%     centroid = [0;0];
%     for i=1:2:Ne*2
%         centroid = centroid + x((Ni-1)*var+i:(Ni-1)*var+i+1);
%     end
%     centroid = centroid/Ne;
    
    cieq(1:Ne,1) = sqrt(sum((reshape(parameters(1:Ne*2,Ni+1),2,Ne) - repmat(final_centroid,[1,Ne])).^2,1)) - epsilon;

%     count = 0;
%     for i=1:2:Ne*2
%         count = count + 1;
%         cieq(count) = norm(x((Ni-1)*var+i:(Ni-1)*var+i+1) - centroid) - epsilon;
%     end
    cieq(Ne+1:Ne+Ni,1) = sqrt(sum((parameters(var-1:var,2:Ni+1) - parameters(var-1:var,1:Ni)).^2,1)) - vpmax*ti;
    
%     count = count + 1;
%     cieq(count) = norm(x(var-1:var) - ip(var-1:var)) - vpmax*ti;
%     for t=2:Ni
%         count = count + 1;
%         cieq(count) = norm(x(var*t-1:var*t) - x(var*(t-1)-1:var*(t-1))) - vpmax*ti;
%     end
end