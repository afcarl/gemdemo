function pps=cls(trainx,yt,testx,lambda,iter)
    % Calibrated least squares
    [n,k]=size(yt);
    [~,d]=size(testx);
    C=chol(0.5*(trainx'*trainx)+lambda*sqrt(n)*eye(d),'lower');  
    % Initialize with least squares
    w=C'\(C\(trainx'*yt));
    pt=trainx*w;
    ps=testx*w;
    % Helper functions for projection onto the simplex
    SimplexProjTwo = @(Y,X,Xtmp) max(bsxfun(@minus,Y,Xtmp(sub2ind(size(Y),(1:size(Y,1))',sum(X>Xtmp,2)))),0);
    SimplexProjOne = @(Y,X) SimplexProjTwo(Y,X,bsxfun(@times,cumsum(X,2)-1,(1./(1:size(Y,2)))));
    SimplexProj = @(Y) SimplexProjOne(Y,sort(Y,2,'descend'));
    % Calibration loop

    [~,trainy]=max(yt,[],2);

    for i=1:iter
        xn=[pt pt.^2/2 pt.^3/6 pt.^4/24];
        xm=[ps ps.^2/2 ps.^3/6 ps.^4/24];
        dd=size(xn,2);
        c=chol(xn'*xn+sqrt(n)*eye(dd),'lower');
        ww=c'\(c\(xn'*yt));
        ppt=SimplexProj(xn*ww);
        pps=SimplexProj(xm*ww);
        g=trainx'*(yt-ppt);
        w=C'\(C\g);
        oldpt=pt;
        pt=ppt+trainx*w;
        ps=pps+testx*w;
        
        [~,yhatt]=max(pt,[],2);
        errort=sum(yhatt~=trainy)/n;
        fprintf('%u,%g\n',i,errort);
        
        normg=norm(oldpt-pt,'fro')/sqrt(n*k);
        if normg<0.002
            break
        end
    end
end