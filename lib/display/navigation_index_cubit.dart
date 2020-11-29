
import 'package:flutter_bloc/flutter_bloc.dart';

class NavigationIndexCubit extends Cubit<int> {
  NavigationIndexCubit(int state) : super(state);

  void setIndex( int i ) => emit( i ) ;
}