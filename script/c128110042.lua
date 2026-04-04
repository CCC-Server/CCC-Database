-- H·C(히로익 챌린저) 앰부시 나이트
local s,id=GetID()

-- 엔진 호환성 체크: EFFECT_DISCARD_COST_REPLACE가 정의되어 있지 않으면 123으로 설정
if not EFFECT_DISCARD_COST_REPLACE then EFFECT_DISCARD_COST_REPLACE=123 end

function s.initial_effect(c)
	-- ①: 패 특수 소환 (절차적 특소)
	c:SetSPSummonOnce(id)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)
	
	-- ②: 자신/상대 턴 릴리스하고 2장까지 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,{id,1})
	e2:SetCost(s.spcost2)
	e2:SetTarget(s.sptg2)
	e2:SetOperation(s.spop2)
	c:RegisterEffect(e2)
	
	-- ③: "히로익" 몬스터 효과의 패 버리기 코스트 대용 (제외)
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EFFECT_DISCARD_COST_REPLACE)
	e3:SetRange(LOCATION_GRAVE)
	e3:SetCondition(s.repcon)
	e3:SetOperation(s.repop)
	c:RegisterEffect(e3)
end

s.listed_series={0x6f, 0x206f} -- 히로익, 히로익 챌린저
s.listed_names={id}

-- ① 조건: 라이프 500 이하 또는 자신 필드에 몬스터 없음
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return (Duel.GetLP(tp)<=500 or Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)==0)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
end

-- ② 비용: 필드의 이 카드를 릴리스
function s.spcost2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsReleasable() end
	Duel.Release(e:GetHandler(),REASON_COST)
end

-- ② 대상 필터 및 타겟: H·C(히로익 챌린저) 몬스터 (0x106f)
function s.spfilter2(c,e,tp)
	return c:IsSetCard(0x106f) and not c:IsCode(id) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		if e:GetHandler():GetSequence()<5 then ft=ft+1 end
		return ft>0 and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end

-- ② 효과 처리
function s.spop2(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if ft>2 then ft=2 end
	if Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then ft=1 end
	
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,aux.NecroValleyFilter(s.spfilter2),tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE,0,1,ft,nil,e,tp)
	if #g>0 then
		local tc=g:GetFirst()
		for tc in aux.Next(g) do
			if Duel.SpecialSummonStep(tc,0,tp,tp,false,false,POS_FACEUP) then
				-- 소환된 몬스터의 레벨을 1 또는 4로 선택 변경
				local opt=Duel.SelectOption(tp,aux.Stringid(id,2),aux.Stringid(id,3))
				local lv=(opt==0 and 1 or 4)
				local e1=Effect.CreateEffect(e:GetHandler())
				e1:SetType(EFFECT_TYPE_SINGLE)
				e1:SetCode(EFFECT_CHANGE_LEVEL)
				e1:SetValue(lv)
				e1:SetReset(RESET_EVENT+RESETS_STANDARD)
				tc:RegisterEffect(e1)
			end
		end
		Duel.SpecialSummonComplete()
	end
	
	-- "히로익" 이외의 특수 소환 제약 (히로익 전체 카드군 코드 0x6f 사용)
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e2:SetDescription(aux.Stringid(id,4)) -- 수정: 구문 오류 해결
	e2:SetTargetRange(1,0)
	e2:SetTarget(s.splimit)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end
function s.splimit(e,c)
	return not c:IsSetCard(0x6f)
end

-- ③ 코스트 대용 조건: 히로익 몬스터 효과 발동 시 패를 버릴 경우 (0x106f)
function s.repcon(e,tp,eg,ep,ev,re,r,rp,chk)
	return r&REASON_COST~=0 and re:IsActiveType(TYPE_MONSTER) 
		and re:GetHandler():IsSetCard(0x6f) and e:GetHandler():IsAbleToRemoveAsCost()
end

-- ③ 코스트 대용 처리: 이 카드를 제외
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(e:GetHandler(),REASON_COST)
end