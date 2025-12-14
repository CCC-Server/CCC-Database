-- 중격괴수황 썬더 카기도라
local s,id=GetID()
local COUNTER_KAIJU=0x37 -- 파괴수 카운터 ID
function s.initial_effect(c)
	-- 카운터 사용 허가 (이 설정이 있어야 카드 자체에 카운터를 놓을 수 있습니다)
	c:EnableCounterPermit(COUNTER_KAIJU)
	
	-- 융합 소환 절차
	c:EnableReviveLimit()
	Fusion.AddProcMixRep(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,0xd3),2,99) -- "파괴수" 몬스터 x 2장 이상
	
	-- 특수 소환 제약 (1턴에 1번)
	c:SetSPSummonOnce(id)

	-- ①: 소환 시 카운터 4개 (이 카드 또는 파괴수 몬스터)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_COUNTER)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F) -- "놓는다"이므로 강제 효과
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1,id) -- ① 효과 1턴에 1번
	e1:SetCondition(s.ctcon)
	e1:SetOperation(s.ctop)
	c:RegisterEffect(e1)

	-- ②: 파괴 내성 (카운터 제거로 대체)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_CONTINUOUS+EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(s.reptg)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
	
	-- ③: 프리 체인 파괴수 특소
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_QUICK_O)
	e3:SetCode(EVENT_FREE_CHAIN)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(1) -- 자신/상대 턴에 1번
	e3:SetTarget(s.sptg)
	e3:SetOperation(s.spop)
	c:RegisterEffect(e3)

	-- ④: 각종 내성 및 제약
	c:SetUniqueOnField(1,0,id)
	-- 소재 불가
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE)
	e4:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCode(EFFECT_CANNOT_BE_FUSION_MATERIAL)
	e4:SetValue(1)
	c:RegisterEffect(e4)
	local e5=e4:Clone()
	e5:SetCode(EFFECT_CANNOT_BE_SYNCHRO_MATERIAL)
	c:RegisterEffect(e5)
	local e6=e4:Clone()
	e6:SetCode(EFFECT_CANNOT_BE_XYZ_MATERIAL)
	c:RegisterEffect(e6)
	local e7=e4:Clone()
	e7:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	c:RegisterEffect(e7)
	-- 컨트롤 변경 불가
	local e8=e4:Clone()
	e8:SetCode(EFFECT_CANNOT_CHANGE_CONTROL)
	c:RegisterEffect(e8)
	-- 릴리스 불가
	local e9=e4:Clone()
	e9:SetCode(EFFECT_UNRELEASABLE_SUM)
	c:RegisterEffect(e9)
	local e10=e4:Clone()
	e10:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	c:RegisterEffect(e10)
end
s.listed_series={0xd3} -- 파괴수
s.counter_place_list={COUNTER_KAIJU} -- 카운터 리스트 등록

-- ① 효과: 조건 (자신 또는 파괴수 특수 소환)
function s.cfilter(c)
	return c:IsFaceup() and c:IsSetCard(0xd3)
end
function s.ctcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsContains(e:GetHandler()) or eg:IsExists(s.cfilter,1,nil)
end
function s.ctop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		c:AddCounter(COUNTER_KAIJU,4)
	end
end

-- ② 효과: 파괴 대체
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsReason(REASON_EFFECT) and not c:IsReason(REASON_REPLACE) 
		and c:IsCanRemoveCounter(tp,COUNTER_KAIJU,1,REASON_EFFECT) end
	return Duel.SelectEffectYesNo(tp,c,96)
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	e:GetHandler():RemoveCounter(tp,COUNTER_KAIJU,1,REASON_EFFECT)
end

-- ③ 효과: 특수 소환
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xd3) and c:IsType(TYPE_MONSTER) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end