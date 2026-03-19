--셀레스티얼 타이탄-시험하는 자 지란
local s,id=GetID()
function s.initial_effect(c)
	-- 싱크로 소환 조건
	Synchro.AddProcedure(c,
		aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_LIGHT),1,1,
		aux.FilterBoolFunction(Card.IsAttribute,ATTRIBUTE_LIGHT),1,99)
	c:EnableReviveLimit()
	-- 펜듈럼 소환
	Pendulum.AddProcedure(c)

	-- E1: 싱크로 소환 성공 시 전개
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCondition(s.spcon)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- E2: 레벨 변경
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetCountLimit(1,{id,1})
	e2:SetTarget(s.lvtg)
	e2:SetOperation(s.lvop)
	c:RegisterEffect(e2)
end

s.listed_series={0xc02}
s.listed_names={id}

-- 공통 소환 제한
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA)
		and not (c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsType(TYPE_SYNCHRO))
end

function s.applylimit(e,tp)
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end

-- 싱크로 소환 성공 시만
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SYNCHRO)
end

-- 펜듈럼 몬스터 필터
function s.pfilter(c,e,tp)
	return c:IsSetCard(0xc02) and c:IsType(TYPE_PENDULUM)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_DEFENSE)
end

-- E1 대상
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.pfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_DECK)
end

-- 레벨 중복 체크
function s.rescon(sg,e,tp,mg)
	return sg:GetClassCount(Card.GetLevel)==#sg
end

-- E1 실행(spop) 수정: SelectSubGroup 제거 및 수동 루프 구현
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if ft<=0 then return end
	if ft>2 then ft=2 end

	local g=Duel.GetMatchingGroup(s.pfilter,tp,LOCATION_DECK,0,nil,e,tp)
	if #g==0 then return end

	local sg=Group.CreateGroup()
	for i=1,ft do
		-- 이미 선택한 카드와 레벨이 다른 카드만 필터링
		local temp_g=g:Filter(function(c)
			return not sg:IsExists(Card.IsLevel,1,nil,c:GetLevel())
		end,nil)
		
		if #temp_g==0 then break end
		
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local sc=temp_g:Select(tp,1,1,nil)
		if #sc>0 then
			sg:Merge(sc)
		end
		-- 1장을 뽑은 후 더 뽑을지 여부를 묻는 창 (최대 ft장까지)
		if i<ft and not Duel.SelectYesNo(tp,aux.Stringid(id,0)) then break end
	end

	if #sg>0 then
		Duel.SpecialSummon(sg,0,tp,tp,false,false,POS_DEFENSE)
		s.applylimit(e,tp)
	end
end

-- 싱크로 몬스터 필터
function s.synfilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SYNCHRO)
end

-- E2 대상
function s.lvtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and s.synfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.synfilter,tp,LOCATION_MZONE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TARGET)
	local g=Duel.SelectTarget(tp,s.synfilter,tp,LOCATION_MZONE,0,1,99,nil)
end

-- E2 실행
function s.lvop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetTargetCards(e)
	if #g==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_LVRANK)
	local lv=Duel.AnnounceLevel(tp,1,4)

	for tc in aux.Next(g) do
		if tc:IsFaceup() and tc:IsRelateToEffect(e) then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_CHANGE_LEVEL)
			e1:SetValue(lv)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			tc:RegisterEffect(e1)
		end
	end

	s.applylimit(e,tp)
end