import 'package:flutter_test/flutter_test.dart';
import 'package:rentease/core/utils/weight_utils.dart';
void main(){ test('sum',(){
 double r(double v)=>(v*20).round()/20;
 final bad=<String>[];
 var s=[0.35,0.35,0.30];
 // random walk of slider drags
 var seed=7;
 for(var i=0;i<3000;i++){
  seed=(seed*1103515245+12345)&0x7fffffff;
  final idx=seed%3; final v=(1+(seed~/3)%18)*0.05;
  final o=[0,1,2].where((x)=>x!=idx).toList();
  final n=normalizeWeights(newValue:v,otherA:s[o[0]],otherB:s[o[1]],round:r);
  s[idx]=n.changed;s[o[0]]=n.otherA;s[o[1]]=n.otherB;
  final t=s[0]+s[1]+s[2];
  if((t-1).abs()>1e-9||s.any((x)=>x<0.05-1e-9)) bad.add('$s drag$idx=$v sum=$t');
 }
 expect(bad,isEmpty);
});}
