--제 9사도-폭룡왕 바칼
local s,id=GetID()
function s.initial_effect(c)
	--싱크로 소환 조건: 드래곤족 튜너 3장 + 튜너 이외 드래곤족 싱크로 몬스터 1장
	Synchro.AddProcedure(c,
		aux.FilterBoolFunctionEx(Card.IsRace,RACE_DRAGON),3,3,  -- 튜너 3장
		aux.FilterBoolFunctionEx(s.matfilter),1,1)			  -- 튜너 이외 드래곤족 싱크로 1장
	c:EnableReviveLimit()
	--이 카드명은 룰상 "드래고니아" 카드로도 취급
	s.listed_series={0xc05} -- "드래고니아"
	--①: 효과로는 파괴되지 않음
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	--②: 공격력 = 묘지의 "드래고니아" 몬스터 수 × 500 (실시간 반영)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)
	--③: 상대가 카드의 효과를 발동했을 때, 필드의 카드 1장을 파괴 (1턴에 2번)
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_CHAINING)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCondition(function(e,tp,eg,ep,ev,re,r,rp) return rp==1-tp end)
	e3:SetCountLimit(2,id) -- 1턴에 2번
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

--싱크로 소재 필터: 튜너 이외 드래곤족 싱크로 몬스터
function s.matfilter(c,scard,sumtype,tp)
	return c:IsRace(RACE_DRAGON,scard,sumtype,tp) and c:IsType(TYPE_SYNCHRO,scard,sumtype,tp) and not c:IsType(TYPE_TUNER,scard,sumtype,tp)
end

--② 공격력 계산 (실시간)
function s.atkval(e,c)
	return Duel.GetMatchingGroupCount(s.atkfilter,c:GetControler(),LOCATION_GRAVE,0,nil)*500
end
function s.atkfilter(c)
	return c:IsSetCard(0xc05) and c:IsMonster()
end 

--③ 대상 지정
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end

--③ 처리: 파괴
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end