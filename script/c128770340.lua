local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Material (E1)
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,s.matfilter,2)
	-------------------------------------------------
	-- ① 효과: 효과로는 파괴되지 않는다
	-------------------------------------------------
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-------------------------------------------------
	-- ② 효과: 융합 소환 성공 시 펜듈럼 카드 2장 배치
	-------------------------------------------------
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCountLimit(1,id)
	e2:SetCondition(s.pzcon)
	e2:SetTarget(s.pztg)
	e2:SetOperation(s.pzop)
	c:RegisterEffect(e2)

	-------------------------------------------------
	-- ③ 효과: Quick - 몬스터 전부 파괴 + 공격력 증가
	-------------------------------------------------
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1,id+100)
	e3:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_BATTLE_START)
	e3:SetTarget(s.destg)
	e3:SetOperation(s.desop)
	c:RegisterEffect(e3)
end

-------------------------------------------------
-- 융합 소재 필터
-------------------------------------------------
function s.matfilter(c,fc,st,tp)
	return c:IsSetCard(0x765)
end

-------------------------------------------------
-- ② 융합 소환 성공 조건
-------------------------------------------------
function s.pzcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
end

-------------------------------------------------
-- ② 펜듈럼 카드 2장을 가져오는 대상 지정
-------------------------------------------------
function s.pztg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.pzfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,2,nil)
			and Duel.CheckLocation(tp,LOCATION_PZONE,0)
			and Duel.CheckLocation(tp,LOCATION_PZONE,1)
	end
end

function s.pzfilter(c)
	return c:IsCode(128770335,128770336)
end

-------------------------------------------------
-- ② 펜듈럼 존에 놓기
-------------------------------------------------
function s.pzop(e,tp,eg,ep,ev,re,r,rp)
	-- 두 카드 검색
	local g=Duel.GetMatchingGroup(s.pzfilter,tp,LOCATION_DECK+LOCATION_EXTRA,0,nil)
	if #g<2 then return end

	local sg=g:Select(tp,2,2,nil)
	local tc1=sg:GetFirst()
	local tc2=sg:GetNext()

	-- 펜듈럼 존 확인
	if Duel.CheckLocation(tp,LOCATION_PZONE,0) then
		Duel.MoveToField(tc1,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
	if Duel.CheckLocation(tp,LOCATION_PZONE,1) then
		Duel.MoveToField(tc2,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end

-------------------------------------------------
-- ③ 몬스터 전부 파괴 + 공격력 상승
-------------------------------------------------
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	local g=Duel.GetMatchingGroup(Card.IsMonster,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	if chk==0 then return #g>0 end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,#g,0,0)
end

function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsMonster,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	local atk=0
	for mc in g:Iter() do
		if mc:GetAttack()>0 then
			atk=atk+mc:GetAttack()
		end
	end
	local ct=Duel.Destroy(g,REASON_EFFECT)
	if ct>0 and atk>0 and c:IsFaceup() and c:IsRelateToEffect(e) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(atk)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD_DISABLE)
		c:RegisterEffect(e1)
	end
end
